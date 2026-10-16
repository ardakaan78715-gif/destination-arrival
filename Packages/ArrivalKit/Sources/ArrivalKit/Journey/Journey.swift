import Foundation

public struct Journey: Sendable, Equatable {
    public let destination: Destination
    public let settings: AlarmSettings
    public private(set) var phase: JourneyPhase = .ready
    public private(set) var estimate: ArrivalEstimate?
    private var speedEstimator = SpeedEstimator()

    public init(destination: Destination, settings: AlarmSettings) {
        self.destination = destination
        self.settings = settings
    }

    public mutating func handle(_ event: JourneyEvent) -> [JourneyEffect] {
        switch (phase, event) {
        case (.ready, .started):
            phase = .tracking
            return [.startLocationUpdates]
        case (.tracking, .locationReceived(let sample)):
            return track(sample)
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

    private mutating func track(_ sample: LocationSample) -> [JourneyEffect] {
        speedEstimator.add(sample)
        let estimate = ArrivalEstimate(
            distance: sample.distance(to: destination),
            speed: speedEstimator.speed,
            settings: settings
        )
        self.estimate = estimate
        guard let reason = estimate.alarmReason else { return [] }
        phase = .ringing(reason)
        return [.stopLocationUpdates, .ringAlarm(reason)]
    }
}
