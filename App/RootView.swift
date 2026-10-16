import ArrivalKit
import SwiftUI

struct RootView: View {
    @Environment(JourneyModel.self) private var journeyModel

    var body: some View {
        Group {
            switch journeyModel.screen {
            case .planning:
                PlanView()
            case .tracking:
                TrackingView()
            case .ringing(let reason):
                AlarmView(reason: reason)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: journeyModel.screen)
        .onChange(of: journeyModel.screen) { _, screen in
            if case .ringing(let reason) = screen, let journey = journeyModel.journey {
                announceAlarm(reason, for: journey)
            }
        }
    }

    private func announceAlarm(_ reason: AlarmReason, for journey: Journey) {
        let title = Formatting.alarmTitle(for: journey.destination)
        let detail = Formatting.alarmReason(reason, for: journey, unit: journeyModel.distanceUnit)
        var announcement = AttributedString("\(title). \(detail)")
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }
}
