import ArrivalKit

@MainActor
protocol LocationService: AnyObject {
    func requestPermission() async -> Bool
    func start(precision: TrackingPrecision) -> AsyncStream<LocationSample>
    func setPrecision(_ precision: TrackingPrecision)
    func stop()
}
