import ArrivalKit
import CoreLocation

@MainActor
final class DeviceLocationService: NSObject, LocationService {
    private let manager = CLLocationManager()
    private var permissionRequests: [CheckedContinuation<Bool, Never>] = []
    private var samples: AsyncStream<LocationSample>.Continuation?
    private var backgroundActivity: CLBackgroundActivitySession?

    override init() {
        super.init()
        manager.delegate = self
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

    func start(precision: TrackingPrecision) -> AsyncStream<LocationSample> {
        samples?.finish()
        let (stream, continuation) = AsyncStream.makeStream(
            of: LocationSample.self,
            bufferingPolicy: .bufferingNewest(16)
        )
        samples = continuation
        setPrecision(precision)
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.pausesLocationUpdatesAutomatically = false
        backgroundActivity?.invalidate()
        backgroundActivity = CLBackgroundActivitySession()
        manager.startUpdatingLocation()
        return stream
    }

    func setPrecision(_ precision: TrackingPrecision) {
        manager.desiredAccuracy = Self.desiredAccuracy(for: precision)
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        backgroundActivity?.invalidate()
        backgroundActivity = nil
        samples?.finish()
        samples = nil
    }

    private static func desiredAccuracy(for precision: TrackingPrecision) -> CLLocationAccuracy {
        switch precision {
        case .economy:
            kCLLocationAccuracyHundredMeters
        case .precise:
            kCLLocationAccuracyBest
        }
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
