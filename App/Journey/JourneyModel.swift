import ArrivalKit
import CoreLocation
import Foundation
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
        case locationLost
    }

    struct ReadinessCheck: Identifiable, Hashable {
        let issues: [ReadinessIssue]

        var id: [ReadinessIssue] {
            issues
        }

        var canStartAnyway: Bool {
            !issues.contains(where: \.isBlocking)
        }
    }

    var draft: Destination?
    var readinessCheck: ReadinessCheck?
    private(set) var journey: Journey?
    private(set) var notice: Notice?
    private(set) var isStarting = false
    let settingsURL: URL?
    let tunnel: TunnelSimulator?

    @ObservationIgnored private let location: any LocationService
    @ObservationIgnored private let alarms: any AlarmService
    @ObservationIgnored private let readiness: any ReadinessProbing
    @ObservationIgnored private let settingsStore: SettingsStore
    @ObservationIgnored private let placeHistory: PlaceHistoryStore
    @ObservationIgnored private var locationTask: Task<Void, Never>?
    @ObservationIgnored private var clockTask: Task<Void, Never>?

    init(dependencies: AppDependencies, settingsStore: SettingsStore, placeHistory: PlaceHistoryStore) {
        location = dependencies.location
        alarms = dependencies.alarms
        readiness = dependencies.readiness
        settingsURL = dependencies.settingsURL
        tunnel = dependencies.tunnel
        self.settingsStore = settingsStore
        self.placeHistory = placeHistory
        alarms.onStopRequested = { [weak self] in self?.stopAlarm() }
        alarms.onBackupDelivered = { [weak self] in self?.send(.backupAlarmFired) }
    }

    var settings: AlarmSettings {
        get { settingsStore.alarm }
        set { settingsStore.alarm = newValue }
    }

    var distanceUnit: DistanceUnit {
        settingsStore.distanceUnit
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

        if await location.requestPermission() {
            await alarms.requestPermission()
        }
        let snapshot = await readiness.snapshot(for: draft, settings: settings)
        let issues = Readiness.issues(for: snapshot)
        if issues.isEmpty {
            readinessCheck = nil
            begin(to: draft)
        } else {
            readinessCheck = ReadinessCheck(issues: issues)
        }
    }

    func startAnyway() {
        guard let draft, readinessCheck?.canStartAnyway == true else { return }
        readinessCheck = nil
        begin(to: draft)
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

    func playTestAlarm() {
        alarms.playTest()
    }

    private func begin(to destination: Destination) {
        guard journey == nil else { return }
        notice = nil
        journey = Journey(destination: destination, settings: settings)
        send(.started(.now))
        placeHistory.update { $0.recordJourney(to: destination) }
    }

    private func endJourney() {
        locationTask?.cancel()
        clockTask?.cancel()
        locationTask = nil
        clockTask = nil
        journey = nil
        notice = nil
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
                alarms.ring(for: journey, reason: reason, unit: distanceUnit)
            }
        case .silenceAlarm:
            alarms.silence()
        }
    }

    private func receive(_ update: LocationUpdate) {
        switch update {
        case .sample(let sample):
            if notice == .locationLost {
                notice = nil
            }
            send(.locationReceived(sample))
        case .accessLost:
            notice = .locationLost
        }
    }

    private func follow(_ updates: AsyncStream<LocationUpdate>) {
        locationTask?.cancel()
        locationTask = Task { [weak self] in
            for await update in updates {
                self?.receive(update)
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
