import ArrivalKit

@MainActor
protocol LocationService: AnyObject {
    func requestPermission() async -> Bool
    func start() -> AsyncStream<LocationSample>
    func stop()
}
