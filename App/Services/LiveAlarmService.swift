import ArrivalKit
import Foundation
import UserNotifications

@MainActor
final class LiveAlarmService: NSObject, AlarmService {
    var onStopRequested: (@MainActor () -> Void)?
    var onBackupDelivered: (@MainActor () -> Void)?

    private let sound: any AlarmSounding
    private let center: UNUserNotificationCenter

    init(sound: any AlarmSounding, center: UNUserNotificationCenter = .current()) {
        self.sound = sound
        self.center = center
        super.init()
        center.delegate = self
        center.setNotificationCategories([AlarmNotification.category])
    }

    var isVolumeLow: Bool {
        sound.isVolumeLow
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func ring(for journey: Journey, reason: AlarmReason) {
        sound.start()
        post(AlarmNotification.ring, content: content(for: journey, reason: reason), after: nil)
    }

    func scheduleBackup(at date: Date, for journey: Journey) {
        let backup = content(for: journey, reason: .scheduledBackup)
        let delay = date.timeIntervalSinceNow
        post(AlarmNotification.firstBackup, content: backup, after: delay)
        post(AlarmNotification.secondBackup, content: backup, after: delay + AlarmNotification.followUpDelay)
    }

    func cancelBackup() {
        center.removePendingNotificationRequests(withIdentifiers: AlarmNotification.backups)
    }

    func silence() {
        sound.stop()
        center.removePendingNotificationRequests(withIdentifiers: AlarmNotification.all)
        center.removeDeliveredNotifications(withIdentifiers: AlarmNotification.all)
    }

    private func content(for journey: Journey, reason: AlarmReason) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = Formatting.alarmTitle(for: journey.destination)
        content.body = Formatting.alarmReason(reason, for: journey)
        content.sound = UNNotificationSound(named: UNNotificationSoundName(AlarmNotification.soundFile))
        content.categoryIdentifier = AlarmNotification.categoryIdentifier
        content.threadIdentifier = AlarmNotification.thread
        return content
    }

    private func post(_ identifier: String, content: UNNotificationContent, after delay: TimeInterval?) {
        let trigger = delay.map { UNTimeIntervalNotificationTrigger(timeInterval: max(1, $0), repeats: false) }
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
}

extension LiveAlarmService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if AlarmNotification.backups.contains(notification.request.identifier) {
            await MainActor.run { self.onBackupDelivered?() }
        }
        return [.banner, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == AlarmNotification.stopAction else { return }
        await MainActor.run { self.onStopRequested?() }
    }
}

private enum AlarmNotification {
    static let categoryIdentifier = "ARRIVAL_ALARM"
    static let stopAction = "STOP"
    static let thread = "arrival"
    static let soundFile = "Alarm.caf"
    static let ring = "arrival.ring"
    static let firstBackup = "arrival.backup.first"
    static let secondBackup = "arrival.backup.second"
    static let backups = [firstBackup, secondBackup]
    static let all = [ring, firstBackup, secondBackup]
    static let followUpDelay: TimeInterval = 60

    static var category: UNNotificationCategory {
        let stop = UNNotificationAction(identifier: stopAction, title: "Stop", options: [])
        return UNNotificationCategory(identifier: categoryIdentifier, actions: [stop], intentIdentifiers: [], options: [])
    }
}
