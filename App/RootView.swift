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
    }
}
