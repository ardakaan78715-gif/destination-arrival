import ArrivalKit
import CoreLocation

@MainActor
final class DeviceLocationService: NSObject, LocationService {
    private let manager = CLLocationManager()
    private var permissionRequests: [CheckedContinuation<Bool, Never>] = []
    private var updates: AsyncStream<LocationUpdate>.Continuation?
    private var backgroundActivity: CLBackgroundActivitySession?

    override init() {
        super.init()
        manager.delegate = self
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .otherNavigation
    }

    var lastKnownSample: LocationSample? {
        manager.location.map(LocationSample.init)
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

    func start(precision: TrackingPrecision) -> AsyncStream<LocationUpdate> {
        updates?.finish()
        let (stream, continuation) = AsyncStream.makeStream(
            of: LocationUpdate.self,
            bufferingPolicy: .bufferingNewest(16)
        )
        updates = continuation
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
        updates?.finish()
        updates = nil
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
        if granted {
            resumeIfTracking()
        } else {
            reportAccessLost()
        }
    }

    private func resumeIfTracking() {
        guard updates != nil else { return }
        manager.startUpdatingLocation()
    }

    private func updatesFailed(with code: CLError.Code) {
        if code == .denied {
            reportAccessLost()
        }
    }

    private func reportAccessLost() {
        updates?.yield(.accessLost)
    }

    private func deliver(_ received: [LocationSample]) {
        received.forEach { updates?.yield(.sample($0)) }
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

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        guard let code = (error as? CLError)?.code, code != .locationUnknown else { return }
        MainActor.assumeIsolated {
            updatesFailed(with: code)
        }
    }
}
