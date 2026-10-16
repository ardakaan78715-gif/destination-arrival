import ArrivalKit
import CoreLocation

@MainActor
final class DeviceLocationService: NSObject, LocationService {
    private let manager = CLLocationManager()
    private var permissionRequests: [CheckedContinuation<Bool, Never>] = []
    private var samples: AsyncStream<LocationSample>.Continuation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .otherNavigation
    }

    func requestPermission() async -> Bool {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                permissionRequests.append(continuation)
                if permissionRequests.count == 1 {
                    manager.requestWhenInUseAuthorization()
                }
            }
        default:
            return false
        }
    }

    func start() -> AsyncStream<LocationSample> {
        samples?.finish()
        let (stream, continuation) = AsyncStream.makeStream(
            of: LocationSample.self,
            bufferingPolicy: .bufferingNewest(16)
        )
        samples = continuation
        manager.startUpdatingLocation()
        return stream
    }

    func stop() {
        manager.stopUpdatingLocation()
        samples?.finish()
        samples = nil
    }

    private func authorizationChanged(to status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        let granted = status == .authorizedWhenInUse || status == .authorizedAlways
        let waiting = permissionRequests
        permissionRequests.removeAll()
        waiting.forEach { $0.resume(returning: granted) }
    }

    private func deliver(_ received: [LocationSample]) {
        received.forEach { samples?.yield($0) }
    }
}

extension DeviceLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            authorizationChanged(to: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let received = locations.map(LocationSample.init)
        MainActor.assumeIsolated {
            deliver(received)
        }
    }
}
