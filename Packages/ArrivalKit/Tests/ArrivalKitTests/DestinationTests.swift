import ArrivalKit
import Testing

@Suite struct DestinationTests {
    @Test func droppedPinIsNamedAndDescribed() {
        let pin = Destination.droppedPin(latitude: 51.522_61, longitude: -0.157_08)

        #expect(pin.name == "Dropped pin")
        #expect(pin.detail == "51.5226, -0.1571")
        #expect(pin.latitude == 51.522_61)
        #expect(pin.longitude == -0.157_08)
    }

    @Test func idCombinesCoordinates() {
        let bakerStreet = Destination(name: "Baker Street", latitude: 51.5226, longitude: -0.1571)

        #expect(bakerStreet.id == "51.5226,-0.1571")
    }

    @Test func coordinateAndLocationUseStoredValues() {
        let bakerStreet = Destination(name: "Baker Street", latitude: 51.5226, longitude: -0.1571)

        #expect(bakerStreet.coordinate.latitude == 51.5226)
        #expect(bakerStreet.coordinate.longitude == -0.1571)
        #expect(bakerStreet.location.coordinate.latitude == 51.5226)
        #expect(bakerStreet.location.coordinate.longitude == -0.1571)
    }
}
