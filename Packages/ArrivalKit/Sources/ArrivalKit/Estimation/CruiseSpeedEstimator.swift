import Foundation

public struct CruiseSpeedEstimator: Sendable, Equatable {
    private struct Step: Sendable, Equatable {
        var end: Date
        var displacement: Double
        var duration: TimeInterval
        var isMoving: Bool
    }

    public let tuning: ArrivalTuning
    public private(set) var cruiseSpeed: Double?
    private var lastSpeedPoint: LocationSample?
    private var latestFixTime: Date?
    private var steps: [Step] = []

    public init(tuning: ArrivalTuning = .standard) {
        self.tuning = tuning
    }

    public var isMoving: Bool {
        guard let step = steps.last, let latestFixTime else { return false }
        return step.isMoving && latestFixTime.timeIntervalSince(step.end) <= tuning.maximumSpeedStep
    }

    public mutating func add(_ fix: LocationSample) {
        guard (0...tuning.maximumSpeedAccuracy).contains(fix.horizontalAccuracy) else { return }
        latestFixTime = fix.timestamp
        let step = recordSpeedPoint(fix)
        let windowStart = fix.timestamp.addingTimeInterval(-tuning.speedWindow)
        steps.removeAll { $0.end < windowStart }
        if step?.isMoving == true {
            updateCruiseSpeed()
        }
    }

    private mutating func recordSpeedPoint(_ fix: LocationSample) -> Step? {
        guard let previous = lastSpeedPoint else {
            lastSpeedPoint = fix
            return nil
        }
        let duration = fix.timestamp.timeIntervalSince(previous.timestamp)
        guard duration >= tuning.speedStep else { return nil }
        lastSpeedPoint = fix
        guard duration <= tuning.maximumSpeedStep else { return nil }
        let displacement = fix.distance(to: previous)
        let noise = max(fix.horizontalAccuracy, previous.horizontalAccuracy)
        let step = Step(
            end: fix.timestamp,
            displacement: displacement,
            duration: duration,
            isMoving: displacement > noise && displacement / duration >= tuning.movingSpeed
        )
        steps.append(step)
        return step
    }

    private mutating func updateCruiseSpeed() {
        let moving = steps.filter(\.isMoving)
        let movingTime = moving.reduce(0) { $0 + $1.duration }
        guard movingTime >= tuning.minimumMovingTime else { return }
        cruiseSpeed = moving.reduce(0) { $0 + $1.displacement } / movingTime
    }
}
