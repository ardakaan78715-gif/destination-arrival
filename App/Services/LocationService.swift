import ArrivalKit

enum LocationUpdate: Sendable, Equatable {
    case sample(LocationSample)
    case accessLost
}

@MainActor
protocol LocationService: AnyObject {
    var lastKnownSample: LocationSample? { get }
    func requestPermission() async -> Bool
    func start(precision: TrackingPrecision) -> AsyncStream<LocationUpdate>
    func setPrecision(_ precision: TrackingPrecision)
    func stop()
}
