import ArrivalKit
import Testing

@Suite struct ServiceAreaTests {
    private let london = ServiceArea.london

    @Test func containsCentralLondonAndHeathrow() {
        #expect(london.contains(latitude: 51.5074, longitude: -0.1278))
        #expect(london.contains(latitude: 51.4700, longitude: -0.4543))
    }

    @Test func containsOuterBoroughs() {
        #expect(london.contains(Destination(name: "Croydon", latitude: 51.3762, longitude: -0.0982)))
        #expect(london.contains(Destination(name: "Romford", latitude: 51.5768, longitude: 0.1801)))
    }

    @Test func excludesBrightonAndOxford() {
        #expect(!london.contains(latitude: 50.8225, longitude: -0.1372))
        #expect(!london.contains(latitude: 51.7520, longitude: -1.2577))
        #expect(!london.contains(Destination(name: "Reading", latitude: 51.4543, longitude: -0.9781)))
    }

    @Test func centreIsMidwayBetweenEdges() {
        #expect(abs(london.centerLatitude - 51.49) < 0.000_001)
        #expect(abs(london.centerLongitude - -0.09) < 0.000_001)
    }
}
