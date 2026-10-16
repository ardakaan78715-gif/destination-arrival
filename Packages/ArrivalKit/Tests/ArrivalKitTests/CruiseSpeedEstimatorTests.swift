import ArrivalKit
import Foundation
import Testing

@Suite struct CruiseSpeedEstimatorTests {
    private let run = FixBuilder(speed: 14, count: 120).jittered(maxMetres: 8, seed: 1)

    @Test func steadyRunMeasuresCruiseSpeed() throws {
        let estimator = estimator(fedWith: run.samples())

        let speed = try #require(estimator.cruiseSpeed)
        #expect(abs(speed - 14) < 0.5)
        #expect(estimator.isMoving)
    }

    @Test func stationDwellKeepsCruiseSpeed() throws {
        let dwell = run.continued(speed: 0, count: 90)
        let nextRun = dwell.continued(speed: 14, count: 120)
        var estimator = estimator(fedWith: run.samples() + dwell.samples())

        let duringDwell = try #require(estimator.cruiseSpeed)
        #expect(abs(duringDwell - 14) < 0.5)
        #expect(!estimator.isMoving)

        nextRun.samples().forEach { estimator.add($0) }
        let afterDwell = try #require(estimator.cruiseSpeed)
        #expect(abs(afterDwell - 14) < 0.5)
        #expect(estimator.isMoving)
    }

    @Test func brakingIntoAStationKeepsCruiseSpeedThroughTheDwell() throws {
        let cruise = FixBuilder(speed: 14, count: 120).jittered(maxMetres: 8, seed: 4)
        let braking = cruise.braking(at: 0.7, count: 21)
        let dwell = braking.continued(speed: 0, count: 180)
        var estimator = estimator(fedWith: cruise.samples() + braking.samples())
        let atStop = try #require(estimator.cruiseSpeed)

        var largestDrift = 0.0
        for fix in dwell.samples() {
            estimator.add(fix)
            largestDrift = max(largestDrift, abs((estimator.cruiseSpeed ?? 0) - atStop))
        }

        #expect(largestDrift < 0.5)
        #expect(!estimator.isMoving)
    }

    @Test func platformJitterIsNotMovement() {
        let platform = FixBuilder(speed: 0, count: 300, accuracy: 10).jittered(maxMetres: 8, seed: 2)

        let estimator = estimator(fedWith: platform.samples())

        #expect(estimator.cruiseSpeed == nil)
        #expect(!estimator.isMoving)
    }

    @Test func coarseFixesDoNotMeasureSpeed() {
        let wifi = FixBuilder(speed: 20, count: 300, accuracy: 150)

        let estimator = estimator(fedWith: wifi.samples())

        #expect(estimator.cruiseSpeed == nil)
        #expect(!estimator.isMoving)
    }

    @Test func stepsWithinTheFixAccuracyAreNotMovement() {
        let shuffle = FixBuilder(speed: 4, count: 300, accuracy: 60)

        let estimator = estimator(fedWith: shuffle.samples())

        #expect(estimator.cruiseSpeed == nil)
        #expect(!estimator.isMoving)
    }

    @Test func gapsLongerThan30SecondsAreIgnored() {
        let sparse = FixBuilder(speed: 14, interval: 40, count: 20)

        let estimator = estimator(fedWith: sparse.samples())

        #expect(estimator.cruiseSpeed == nil)
        #expect(!estimator.isMoving)
    }

    @Test func needsThirtySecondsOfMovement() throws {
        let samples = FixBuilder(speed: 14, count: 31).samples()
        var estimator = estimator(fedWith: Array(samples.prefix(30)))

        #expect(estimator.cruiseSpeed == nil)

        estimator.add(samples[30])
        let speed = try #require(estimator.cruiseSpeed)
        #expect(abs(speed - 14) < 0.5)
    }

    @Test func remembersCruiseSpeedAfterWindowEmpties() throws {
        let platform = run.continued(speed: 0, count: 600)

        let estimator = estimator(fedWith: run.samples() + platform.samples())

        let speed = try #require(estimator.cruiseSpeed)
        #expect(abs(speed - 14) < 0.5)
        #expect(!estimator.isMoving)
    }

    private func estimator(fedWith samples: [LocationSample]) -> CruiseSpeedEstimator {
        var estimator = CruiseSpeedEstimator()
        samples.forEach { estimator.add($0) }
        return estimator
    }
}
