import ArrivalKit
import SwiftUI

struct SearchSuggestionRow: View {
    let destination: Destination
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .foregroundStyle(.primary)
                if let detail = destination.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
        }
    }
}
