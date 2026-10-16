import ArrivalKit
import SwiftUI

struct StatusChip: View {
    let status: SignalStatus
    let now: Date

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.15), in: Capsule())
    }

    private var title: String {
        switch status {
        case .live:
            "Live GPS"
        case .stopped:
            "Stopped"
        case .waitingToMove:
            "Waiting to move"
        case .estimating(let since):
            "No signal for \(Formatting.duration(now.timeIntervalSince(since))) · estimating"
        }
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
