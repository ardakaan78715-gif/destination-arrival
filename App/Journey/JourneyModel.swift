import ArrivalKit
import CoreLocation
import Observation

@MainActor
@Observable
final class JourneyModel {
    enum Screen: Equatable {
        case planning
        case tracking
        case ringing(AlarmReason)
    }

    enum Notice: Hashable {
        case outsideLondon
        case locationDenied
        case notificationsOff
        case volumeLow

        var message: String {
            switch self {
            case .outsideLondon:
                "Pick somewhere in London for now."
            case .locationDenied:
                "Location is off for Destination Arrival. Turn it on in Settings so the alarm knows where you are."
            case .notificationsOff:
                "Notifications are off. The alarm can only sound while the app is running."
            case .volumeLow:
                "Turn your volume up. The alarm uses media volume."
            }
        }
    }

    var draft: Destination?
    var settings = AlarmSettings()
    private(set) var journey: Journey?
    private(set) var notices: [Notice] = []
    private(set) var isStarting = false
    let tunnel: TunnelSimulator?

    @ObservationIgnored private let location: any LocationService
    @ObservationIgnored private let alarms: any AlarmService
    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private var clockTask: Task<Void, Never>?

    init(location: any LocationService, alarms: any AlarmService, tunnel: TunnelSimulator?) {
        self.location = location
        self.alarms = alarms
        self.tunnel = tunnel
        alarms.onStopRequested = { [weak self] in self?.stopAlarm() }
        alarms.onBackupDelivered = { [weak self] in self?.send(.backupAlarmFired) }
    }

    var screen: Screen {
        switch journey?.phase {
        case .tracking:
            .tracking
        case .ringing(let reason):
            .ringing(reason)
        case .ready, .finished, nil:
            .planning
        }
    }

    func select(_ destination: Destination) {
        draft = destination
        notices = []
    }

    func dropPin(at coordinate: CLLocationCoordinate2D) {
        let pin = Destination.droppedPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard ServiceArea.london.contains(pin) else {
            notices = [.outsideLondon]
            return
        }
        select(pin)
    }

    func start() async {
        guard let draft, journey == nil, !isStarting else { return }
        guard ServiceArea.london.contains(draft) else {
            notices = [.outsideLondon]
            return
        }
        isStarting = true
        defer { isStarting = false }

        guard await location.requestPermission() else {
            notices = [.locationDenied]
            return
        }
        let notificationsAllowed = await alarms.requestPermission()
        notices = warnings(notificationsAllowed: notificationsAllowed)
        journey = Journey(destination: draft, settings: settings)
        send(.started(.now))
    }

    func stopAlarm() {
        switch journey?.phase {
        case .ringing:
            send(.alarmStopped)
            endJourney()
        case .tracking:
            cancel()
            alarms.silence()
        case .ready, .finished, nil:
            alarms.silence()
        }
    }

    func cancel() {
        send(.cancelled)
        endJourney()
    }

    private func warnings(notificationsAllowed: Bool) -> [Notice] {
        var warnings: [Notice] = []
        if !notificationsAllowed {
            warnings.append(.notificationsOff)
        }
        if alarms.isVolumeLow {
            warnings.append(.volumeLow)
        }
        return warnings
    }

    private func endJourney() {
        locationTask?.cancel()
        clockTask?.cancel()
        locationTask = nil
        clockTask = nil
        journey = nil
    }

    private func send(_ event: JourneyEvent) {
        guard var journey else { return }
        let effects = journey.handle(event)
        self.journey = journey
        effects.forEach(perform)
    }

    private func perform(_ effect: JourneyEffect) {
        switch effect {
        case .startLocationUpdates(let precision):
            follow(location.start(precision: precision))
            startClock()
        case .changePrecision(let precision):
            location.setPrecision(precision)
        case .stopLocationUpdates:
            location.stop()
            clockTask?.cancel()
        case .scheduleBackupAlarm(let date):
            if let journey {
                alarms.scheduleBackup(at: date, for: journey)
            }
        case .cancelBackupAlarm:
            alarms.cancelBackup()
        case .ringAlarm(let reason):
            if let journey {
                alarms.ring(for: journey, reason: reason)
            }
        case .silenceAlarm:
            alarms.silence()
        }
    }

    private func follow(_ samples: AsyncStream<LocationSample>) {
        locationTask?.cancel()
        locationTask = Task { [weak self] in
            for await sample in samples {
                self?.send(.locationReceived(sample))
            }
        }
    }

    private func startClock() {
        clockTask?.cancel()
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(10))
                } catch {
                    return
                }
                self?.send(.clockTicked(.now))
            }
        }
    }
}
