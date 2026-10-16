import Foundation

public struct SpeedEstimator: Sendable, Equatable {
    public static let window: TimeInterval = 60
    public static let minimumSpan: TimeInterval = 20
    public static let maximumAccuracy: Double = 100
    public static let minimumSpeed: Double = 1

    private var samples: [LocationSample] = []

    public init() {}

    public mutating func add(_ sample: LocationSample) {
        guard (0...Self.maximumAccuracy).contains(sample.horizontalAccuracy) else { return }
        if let last = samples.last, sample.timestamp <= last.timestamp { return }
        samples.append(sample)
        samples.removeAll { sample.timestamp.timeIntervalSince($0.timestamp) > Self.window }
    }

    public var speed: Double? {
        guard let first = samples.first, let last = samples.last else { return nil }
        let span = last.timestamp.timeIntervalSince(first.timestamp)
        guard span >= Self.minimumSpan else { return nil }
        let travelled = zip(samples, samples.dropFirst()).reduce(0) { total, step in
            total + step.0.distance(to: step.1)
        }
        let speed = travelled / span
        return speed >= Self.minimumSpeed ? speed : nil
    }
}
