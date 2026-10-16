import ArrivalKit
import SwiftUI

struct AlarmView: View {
    @Environment(JourneyModel.self) private var journeyModel
    let reason: AlarmReason
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "alarm.fill")
                .font(.system(size: 72, weight: .bold))
                .scaleEffect(isPulsing ? 1.08 : 0.94)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            if let journey = journeyModel.journey {
                Text(Formatting.alarmTitle(for: journey.destination))
                    .font(.largeTitle.bold())
                Text(Formatting.alarmReason(reason, for: journey, unit: journeyModel.distanceUnit))
                    .font(.title3)
            }
            Spacer()
            Button {
                journeyModel.stopAlarm()
            } label: {
                Text("I'm awake")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .background(.black, in: RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.black)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange.ignoresSafeArea())
        .onAppear { isPulsing = true }
    }
}
