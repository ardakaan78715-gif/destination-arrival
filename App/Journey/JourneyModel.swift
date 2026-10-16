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

    enum Notice: Equatable {
        case outsideLondon
        case locationDenied
        case notificationsOff

        var message: String {
            switch self {
            case .outsideLondon:
                "Pick somewhere in London for now."
            case .locationDenied:
                "Location is off for Destination Arrival. Turn it on in Settings so the alarm knows where you are."
            case .notificationsOff:
                "Notifications are off. The alarm can only sound while the app is running."
            }
        }
    }

    var draft: Destination?
    var settings = AlarmSettings()
    private(set) var journey: Journey?
    private(set) var notice: Notice?
    private(set) var isStarting = false

    @ObservationIgnored private let location: any LocationService
    @ObservationIgnored private let alarms: any AlarmService
    @ObservationIgnored private var locationTask: Task<Void, Never>?

    init(location: any LocationService, alarms: any AlarmService) {
        self.location = location
        self.alarms = alarms
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
        notice = nil
    }

    func dropPin(at coordinate: CLLocationCoordinate2D) {
        let pin = Destination.droppedPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard ServiceArea.london.contains(pin) else {
            notice = .outsideLondon
            return
        }
        select(pin)
    }

    func start() async {
        guard let draft, journey == nil, !isStarting else { return }
        guard ServiceArea.london.contains(draft) else {
            notice = .outsideLondon
            return
        }
        isStarting = true
        defer { isStarting = false }

        guard await location.requestPermission() else {
            notice = .locationDenied
            return
        }
        let notificationsAllowed = await alarms.requestPermission()
        notice = notificationsAllowed ? nil : .notificationsOff
        journey = Journey(destination: draft, settings: settings)
        send(.started(.now))
    }

    func stopAlarm() {
        send(.alarmStopped)
        endJourney()
    }

    func cancel() {
        send(.cancelled)
        endJourney()
    }

    private func endJourney() {
        locationTask?.cancel()
        locationTask = nil
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
        case .startLocationUpdates:
            follow(location.start())
        case .stopLocationUpdates:
            location.stop()
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
}
