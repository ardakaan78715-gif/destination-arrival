import ArrivalKit

struct PlaceSuggestion: Identifiable, Equatable {
    var destination: Destination
    var isStation: Bool

    var id: String {
        destination.id
    }
}

@MainActor
protocol PlaceSearching {
    func suggestions(for query: String) async throws -> [PlaceSuggestion]
}
