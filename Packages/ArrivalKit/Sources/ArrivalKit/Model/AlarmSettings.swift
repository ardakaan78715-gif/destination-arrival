import Foundation

public struct AlarmSettings: Sendable, Hashable, Codable {
    public static let leadTimeChoices: [TimeInterval] = [60, 120, 180, 300, 600]
    public static let radiusRange: ClosedRange<Double> = 200...3000
    public static let radiusStep: Double = 50

    public var leadTime: TimeInterval
    public var radius: Double

    public init(leadTime: TimeInterval = 120, radius: Double = 750) {
        self.leadTime = Self.snappedLeadTime(leadTime)
        self.radius = Self.clampedRadius(radius)
    }

    private static func snappedLeadTime(_ value: TimeInterval) -> TimeInterval {
        leadTimeChoices.reduce(leadTimeChoices[0]) { best, choice in
            abs(choice - value) < abs(best - value) ? choice : best
        }
    }

    private static func clampedRadius(_ value: Double) -> Double {
        let stepped = (value / radiusStep).rounded() * radiusStep
        return min(max(stepped, radiusRange.lowerBound), radiusRange.upperBound)
    }
}
