import Foundation

public struct ArrivalTuning: Sendable, Equatable {
    public var maximumAccuracy: Double
    public var maximumSpeedAccuracy: Double
    public var maximumPlausibleSpeed: Double
    public var staleFixAllowance: TimeInterval
    public var speedStep: TimeInterval
    public var maximumSpeedStep: TimeInterval
    public var movingSpeed: Double
    public var speedWindow: TimeInterval
    public var minimumMovingTime: TimeInterval
    public var signalLossAfter: TimeInterval
    public var cautionFactor: Double
    public var fastTrainSpeed: Double

    public static let standard = ArrivalTuning(
        maximumAccuracy: 200,
        maximumSpeedAccuracy: 100,
        maximumPlausibleSpeed: 90,
        staleFixAllowance: 60,
        speedStep: 10,
        maximumSpeedStep: 30,
        movingSpeed: 2.5,
        speedWindow: 180,
        minimumMovingTime: 30,
        signalLossAfter: 45,
        cautionFactor: 1.1,
        fastTrainSpeed: 15
    )
}
