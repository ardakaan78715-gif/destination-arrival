import Foundation

public enum TrackingPrecision: Sendable, Equatable {
    case economy
    case precise

    public static func required(for estimate: ArrivalEstimate, at date: Date) -> TrackingPrecision {
        let tuning = estimate.tuning
        let isNearby = estimate.distanceRemaining(at: date) <= tuning.precisionDistance
        let isSoon = estimate.timeRemaining(at: date) <= tuning.precisionTime
        return isNearby || isSoon ? .precise : .economy
    }
}
