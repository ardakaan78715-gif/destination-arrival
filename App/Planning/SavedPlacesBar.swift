import ArrivalKit
import SwiftUI

struct SavedPlacesBar: View {
    @Environment(PlaceHistoryStore.self) private var placeHistory
    @Environment(JourneyModel.self) private var journeyModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(placeHistory.history.favourites) { place in
                    chip(for: place, systemImage: "star.fill")
                }
                ForEach(placeHistory.history.recents) { place in
                    chip(for: place, systemImage: "clock")
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func chip(for place: Destination, systemImage: String) -> some View {
        Button {
            journeyModel.select(place)
        } label: {
            Label(place.name, systemImage: systemImage)
                .font(.subheadline)
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive) {
                placeHistory.update { $0.remove(place) }
            }
        }
    }
}
