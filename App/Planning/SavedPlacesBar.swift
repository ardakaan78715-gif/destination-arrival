import ArrivalKit
import SwiftUI

struct SavedPlacesBar: View {
    @Environment(PlaceHistoryStore.self) private var placeHistory
    @Environment(JourneyModel.self) private var journeyModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(placeHistory.history.favourites) { place in
                    chip(for: place, kind: .favourite)
                }
                ForEach(placeHistory.history.recents) { place in
                    chip(for: place, kind: .recent)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func chip(for place: Destination, kind: PlaceKind) -> some View {
        Button {
            journeyModel.select(place)
        } label: {
            Label(place.name, systemImage: kind.systemImage)
                .font(.subheadline)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive) {
                remove(place)
            }
        }
        .accessibilityLabel(kind.spokenLabel(name: place.name))
        .accessibilityAction(named: "Remove") {
            remove(place)
        }
    }

    private func remove(_ place: Destination) {
        placeHistory.update { $0.remove(place) }
    }
}
