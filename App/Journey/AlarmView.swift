import ArrivalKit
import SwiftUI

struct AlarmView: View {
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var awakeButtonHeight: CGFloat = 88
    @State private var hasAppeared = false
    let reason: AlarmReason

    var body: some View {
        VStack(spacing: 24) {
            ViewThatFits(in: .vertical) {
                message
                    .frame(maxHeight: .infinity)
                ScrollView {
                    message
                }
            }
            awakeButton
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange.ignoresSafeArea())
        .sensoryFeedback(.warning, trigger: hasAppeared)
        .onAppear { hasAppeared = true }
    }

    private var isPulsing: Bool {
        hasAppeared && !reduceMotion
    }

    private var pulse: Animation? {
        isPulsing ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : nil
    }

    private var message: some View {
        VStack(spacing: 24) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 72, weight: .bold))
                .scaleEffect(isPulsing ? 1.1 : 1)
                .animation(pulse, value: isPulsing)
                .accessibilityHidden(true)
            if let journey = journeyModel.journey {
                Text(Formatting.alarmTitle(for: journey.destination))
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(Formatting.alarmReason(reason, for: journey, unit: journeyModel.distanceUnit))
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var awakeButton: some View {
        Button {
            journeyModel.stopAlarm()
        } label: {
            Text("I'm awake")
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity, minHeight: awakeButtonHeight)
                .background(.black, in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Stops the alarm and ends the journey")
    }
}
