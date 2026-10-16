import ArrivalKit
import MapKit

@MainActor
struct LocalPlaceSearch: PlaceSearching {
    var area = ServiceArea.london

    func suggestions(for query: String) async throws -> [PlaceSuggestion] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = area.region
        request.resultTypes = [.pointOfInterest, .address]
        let response = try await MKLocalSearch(request: request).start()

        var seen = Set<String>()
        let suggestions = response.mapItems
            .map(PlaceSuggestion.init)
            .filter { area.contains($0.destination) }
            .filter { seen.insert($0.id).inserted }
        return suggestions.filter(\.isStation) + suggestions.filter { !$0.isStation }
    }
}

private extension PlaceSuggestion {
    init(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        let name = item.name ?? "Unnamed place"
        let address = item.placemark.title
        self.init(
            destination: Destination(
                name: name,
                detail: address == name ? nil : address,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            isStation: item.pointOfInterestCategory == .publicTransport
        )
    }
}
