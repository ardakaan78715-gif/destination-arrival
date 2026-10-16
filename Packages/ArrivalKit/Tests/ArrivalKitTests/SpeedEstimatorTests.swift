import ArrivalKit
import Foundation
import Testing

@Suite struct SpeedEstimatorTests {
    @Test func steadyApproachMeasuresSpeed() throws {
        var estimator = SpeedEstimator()
        FixBuilder(speed: 15, count: 61).samples().forEach { estimator.add($0) }

        let speed = try #require(estimator.speed)
        #expect(abs(speed - 15) < 0.3)
    }

    @Test func unknownUntilTwentySecondsOfData() {
        var estimator = SpeedEstimator()
        let samples = FixBuilder(speed: 15, count: 21).samples()

        samples.prefix(20).forEach { estimator.add($0) }
        #expect(estimator.speed == nil)

        estimator.add(samples[20])
        #expect(estimator.speed != nil)
    }

    @Test func stationaryPhoneHasNoSpeed() {
        var estimator = SpeedEstimator()
        FixBuilder(speed: 0, count: 120).samples().forEach { estimator.add($0) }

        #expect(estimator.speed == nil)
    }

    @Test func skipsInaccurateAndOutOfOrderFixes() throws {
        var estimator = SpeedEstimator()
        let samples = FixBuilder(speed: 15, count: 31).samples()
        samples.forEach { estimator.add($0) }
        let measured = try #require(estimator.speed)

        var coarse = samples[30]
        coarse.timestamp.addTimeInterval(1)
        coarse.latitude += 0.01
        coarse.horizontalAccuracy = 150
        estimator.add(coarse)

        var late = samples[30]
        late.longitude += 0.01
        estimator.add(late)

        #expect(estimator.speed == measured)
    }

    @Test func forgetsFixesOlderThanTheWindow() {
        var estimator = SpeedEstimator()
        let moving = FixBuilder(speed: 20, count: 60).samples()
        let last = moving[59]
        let stopped = FixBuilder(
            latitude: last.latitude,
            longitude: last.longitude,
            start: last.timestamp.addingTimeInterval(1),
            speed: 0,
            count: 90
        ).samples()

        (moving + stopped).forEach { estimator.add($0) }

        #expect(estimator.speed == nil)
    }
}
