import ArrivalKit
import SwiftUI

struct StatusChip: View {
    let status: SignalStatus
    let now: Date

    var body: some View {
        Label {
            Text(Formatting.signalStatus(status, at: now))
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(tint)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Formatting.spokenSignalStatus(status, at: now))
    }

    private var symbol: String {
        switch status {
        case .live:
            "location.fill"
        case .stopped:
            "pause.circle"
        case .waitingToMove:
            "hourglass"
        case .estimating:
            "antenna.radiowaves.left.and.right.slash"
        }
    }

    private var tint: Color {
        switch status {
        case .live:
            .green
        case .stopped, .waitingToMove:
            .secondary
        case .estimating:
            .orange
        }
    }
}
