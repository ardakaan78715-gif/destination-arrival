import ArrivalKit
import Foundation
import Testing

@Suite struct PlaceHistoryTests {
    private let bakerStreet = Destination(name: "Baker Street", latitude: 51.5226, longitude: -0.1571)
    private let kingsCross = Destination(name: "King's Cross St Pancras", latitude: 51.5308, longitude: -0.1238)
    private let oxfordCircus = Destination(name: "Oxford Circus", latitude: 51.5152, longitude: -0.1419)

    @Test func recordingMovesPlaceToFront() {
        var history = PlaceHistory()

        history.recordJourney(to: bakerStreet)
        history.recordJourney(to: kingsCross)
        history.recordJourney(to: oxfordCircus)
        history.recordJourney(to: bakerStreet)

        #expect(history.recents.map(\.name) == ["Baker Street", "Oxford Circus", "King's Cross St Pancras"])
    }

    @Test func nearbyDuplicatesCollapse() {
        var history = PlaceHistory()
        let bakerStreetExit = Destination(name: "Baker Street exit", latitude: 51.5229, longitude: -0.1571)
        let madameTussauds = Destination(name: "Madame Tussauds", latitude: 51.5226, longitude: -0.1555)

        history.recordJourney(to: bakerStreet)
        history.recordJourney(to: bakerStreetExit)
        history.recordJourney(to: madameTussauds)

        #expect(history.recents.map(\.name) == ["Madame Tussauds", "Baker Street exit"])
    }

    @Test func recentsAreCappedAtEight() {
        var history = PlaceHistory()
        let places = (0..<10).map { index in
            Destination(name: "Place \(index)", latitude: 51.40 + Double(index) * 0.01, longitude: -0.12)
        }

        places.forEach { history.recordJourney(to: $0) }

        #expect(history.recents.count == PlaceHistory.recentsLimit)
        #expect(history.recents.first?.name == "Place 9")
        #expect(history.recents.last?.name == "Place 2")
    }

    @Test func favouritesStayOutOfRecents() {
        var history = PlaceHistory()
        history.recordJourney(to: bakerStreet)
        history.recordJourney(to: kingsCross)

        history.toggleFavourite(bakerStreet)
        history.recordJourney(to: bakerStreet)

        #expect(history.favourites == [bakerStreet])
        #expect(history.recents == [kingsCross])
    }

    @Test func toggleFavouriteAddsAndRemoves() {
        var history = PlaceHistory()
        let nearbyPin = Destination.droppedPin(latitude: 51.5228, longitude: -0.1572)

        history.toggleFavourite(bakerStreet)

        #expect(history.isFavourite(bakerStreet))
        #expect(history.isFavourite(nearbyPin))
        #expect(!history.isFavourite(kingsCross))

        history.toggleFavourite(nearbyPin)

        #expect(history.favourites.isEmpty)
        #expect(!history.isFavourite(bakerStreet))
    }

    @Test func removeDeletesEverywhere() {
        var history = PlaceHistory()
        history.recordJourney(to: kingsCross)
        history.recordJourney(to: oxfordCircus)
        history.toggleFavourite(bakerStreet)

        history.remove(bakerStreet)
        history.remove(kingsCross)

        #expect(history.favourites.isEmpty)
        #expect(history.recents == [oxfordCircus])
        #expect(!history.isEmpty)

        history.remove(oxfordCircus)

        #expect(history.isEmpty)
    }

    @Test func codableRoundTrip() throws {
        var history = PlaceHistory()
        history.recordJourney(to: kingsCross)
        history.recordJourney(to: Destination.droppedPin(latitude: 51.5033, longitude: -0.1196))
        history.toggleFavourite(bakerStreet)

        let data = try JSONEncoder().encode(history)

        #expect(try JSONDecoder().decode(PlaceHistory.self, from: data) == history)
    }
}
