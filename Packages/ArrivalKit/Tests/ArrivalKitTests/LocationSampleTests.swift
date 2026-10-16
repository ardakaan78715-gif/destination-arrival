import ArrivalKit
import CoreLocation
import Testing

@Suite struct LocationSampleTests {
    @Test func initFromCLLocationCopiesFields() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 51.5226, longitude: -0.1571),
            altitude: 30,
            horizontalAccuracy: 12,
            verticalAccuracy: 5,
            timestamp: FixBuilder.startDate
        )

        let sample = LocationSample(location)

        #expect(sample.latitude == 51.5226)
        #expect(sample.longitude == -0.1571)
        #expect(sample.horizontalAccuracy == 12)
        #expect(sample.timestamp == FixBuilder.startDate)
    }

    @Test func distanceBakerStreetToKingsCrossIsAbout2480Metres() {
        let bakerStreet = LocationSample(
            latitude: 51.5226,
            longitude: -0.1571,
            horizontalAccuracy: 5,
            timestamp: FixBuilder.startDate
        )
        let kingsCross = Destination(name: "King's Cross St Pancras", latitude: 51.5308, longitude: -0.1238)

        #expect(abs(bakerStreet.distance(to: kingsCross) - 2_480) < 100)
    }

    @Test func closestPossibleDistanceSubtractsAccuracy() {
        let kingsCross = Destination(name: "King's Cross St Pancras", latitude: 51.5308, longitude: -0.1238)
        let coarse = LocationSample(
            latitude: 51.5226,
            longitude: -0.1571,
            horizontalAccuracy: 150,
            timestamp: FixBuilder.startDate
        )
        let alongside = LocationSample(
            latitude: 51.5310,
            longitude: -0.1238,
            horizontalAccuracy: 65,
            timestamp: FixBuilder.startDate
        )

        #expect(coarse.closestPossibleDistance(to: kingsCross) == coarse.distance(to: kingsCross) - 150)
        #expect(alongside.closestPossibleDistance(to: kingsCross) == 0)
    }

    @Test func distanceToSampleMatchesDistanceToDestination() {
        let samples = FixBuilder(speed: 100, count: 11).samples()
        let end = samples[10]
        let destination = Destination(name: "End", latitude: end.latitude, longitude: end.longitude)

        #expect(samples[0].distance(to: end) == samples[0].distance(to: destination))
        #expect(abs(samples[0].distance(to: end) - 1_000) < 10)
    }
}
