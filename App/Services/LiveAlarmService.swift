import ArrivalKit
import UserNotifications

@MainActor
final class LiveAlarmService: NSObject, AlarmService {
    private static let ringIdentifier = "arrival.ring"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func ring(for journey: Journey, reason: AlarmReason) {
        let content = UNMutableNotificationContent()
        content.title = Formatting.alarmTitle(for: journey.destination)
        content.body = Formatting.alarmReason(reason, settings: journey.settings)
        content.sound = .default
        let request = UNNotificationRequest(identifier: Self.ringIdentifier, content: content, trigger: nil)
        Task {
            try? await center.add(request)
        }
    }

    func silence() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.ringIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.ringIdentifier])
    }
}

extension LiveAlarmService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
