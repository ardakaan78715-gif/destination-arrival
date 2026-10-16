import ArrivalKit
import SwiftUI

struct SearchSuggestionRow: View {
    let destination: Destination
    let kind: PlaceKind

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
            Image(systemName: kind.systemImage)
                .foregroundStyle(.tint)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(kind.spokenLabel(name: destination.name, detail: destination.detail))
    }
}

enum PlaceKind {
    case favourite
    case recent
    case station
    case place

    var systemImage: String {
        switch self {
        case .favourite:
            "star.fill"
        case .recent:
            "clock"
        case .station:
            "tram.fill"
        case .place:
            "mappin"
        }
    }

    func spokenLabel(name: String, detail: String? = nil) -> String {
        [name, detail, spokenName].compactMap { $0 }.joined(separator: ", ")
    }

    private var spokenName: String? {
        switch self {
        case .favourite:
            "Favourite"
        case .recent:
            "Recent"
        case .station:
            "Station"
        case .place:
            nil
        }
    }
}
