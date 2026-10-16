import Foundation
import Observation

@MainActor
@Observable
final class PlaceSearchModel {
    var query = ""
    private(set) var results: [PlaceSuggestion] = []
    private(set) var isSearching = false

    @ObservationIgnored private let places: any PlaceSearching

    init(places: any PlaceSearching) {
        self.places = places
    }

    func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else {
            results = []
            isSearching = false
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }

        isSearching = true
        let found = try? await places.suggestions(for: text)
        guard !Task.isCancelled else { return }
        isSearching = false
        if let found {
            results = found
        }
    }
}
