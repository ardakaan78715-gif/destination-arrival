import Foundation

public struct Journey: Sendable, Equatable {
    public let destination: Destination
    public let settings: AlarmSettings
    public private(set) var phase: JourneyPhase = .ready
    public private(set) var estimate: ArrivalEstimate?
    public private(set) var precision: TrackingPrecision = .economy
    private let tuning: ArrivalTuning
    private var fixFilter: FixFilter?
    private var speedEstimator: CruiseSpeedEstimator

    public init(destination: Destination, settings: AlarmSettings, tuning: ArrivalTuning = .standard) {
        self.destination = destination
        self.settings = settings
        self.tuning = tuning
        self.speedEstimator = CruiseSpeedEstimator(tuning: tuning)
    }

    public mutating func handle(_ event: JourneyEvent) -> [JourneyEffect] {
        switch (phase, event) {
        case (.ready, .started(let date)):
            phase = .tracking
            fixFilter = FixFilter(journeyStart: date, tuning: tuning)
            return [.startLocationUpdates(precision)]
        case (.tracking, .locationReceived(let fix)):
            return track(fix)
        case (.tracking, .clockTicked(let date)):
            return evaluate(at: date)
        case (.tracking, .cancelled):
            phase = .finished
            return [.stopLocationUpdates]
        case (.ringing, .alarmStopped), (.ringing, .cancelled):
            phase = .finished
            return [.silenceAlarm]
        default:
            return []
        }
    }

    private mutating func track(_ fix: LocationSample) -> [JourneyEffect] {
        guard fixFilter?.accept(fix) == .accepted else { return [] }
        speedEstimator.add(fix)
        estimate = ArrivalEstimate(
            anchor: fix,
            destination: destination,
            cruiseSpeed: speedEstimator.cruiseSpeed,
            isMoving: speedEstimator.isMoving,
            settings: settings,
            tuning: tuning
        )
        return evaluate(at: fix.timestamp)
    }

    private mutating func evaluate(at date: Date) -> [JourneyEffect] {
        guard let estimate else { return [] }
        if let reason = estimate.alarmReason(at: date) {
            phase = .ringing(reason)
            return [.stopLocationUpdates, .ringAlarm(reason)]
        }
        return refinePrecision(for: estimate, at: date)
    }

    private mutating func refinePrecision(for estimate: ArrivalEstimate, at date: Date) -> [JourneyEffect] {
        guard precision == .economy, TrackingPrecision.required(for: estimate, at: date) == .precise else {
            return []
        }
        precision = .precise
        return [.changePrecision(.precise)]
    }
}
