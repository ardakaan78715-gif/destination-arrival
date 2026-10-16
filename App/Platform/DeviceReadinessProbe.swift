import ArrivalKit
import CoreLocation
import Foundation
import UserNotifications

@MainActor
final class DeviceReadinessProbe: ReadinessProbing {
    private let manager = CLLocationManager()
    private let location: any LocationService
    private let sound: any AlarmSounding
    private let notifications: UNUserNotificationCenter

    init(
        location: any LocationService,
        sound: any AlarmSounding,
        notifications: UNUserNotificationCenter = .current()
    ) {
        self.location = location
        self.sound = sound
        self.notifications = notifications
    }

    func snapshot(for destination: Destination, settings: AlarmSettings) async -> ReadinessSnapshot {
        let notificationStatus = await notifications.notificationSettings().authorizationStatus
        return ReadinessSnapshot(
            location: Self.locationAccess(for: manager.authorizationStatus),
            hasPreciseLocation: manager.accuracyAuthorization == .fullAccuracy,
            notifications: Self.notificationAccess(for: notificationStatus),
            isLowPowerModeOn: ProcessInfo.processInfo.isLowPowerModeEnabled,
            isVolumeLow: sound.isVolumeLow,
            distanceToDestination: Readiness.distance(from: location.lastKnownSample, to: destination, at: .now),
            radius: settings.radius
        )
    }

    private static func locationAccess(for status: CLAuthorizationStatus) -> LocationAccess {
        switch status {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .authorizedWhenInUse:
            .whenInUse
        case .authorizedAlways:
            .always
        @unknown default:
            .notDetermined
        }
    }

    private static func notificationAccess(for status: UNAuthorizationStatus) -> NotificationAccess {
        switch status {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        default:
            .allowed
        }
    }
}
