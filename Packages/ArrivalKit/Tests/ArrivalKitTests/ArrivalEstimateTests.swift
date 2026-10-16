import ArrivalKit
import Testing

@Suite struct ArrivalEstimateTests {
    private let route = FixBuilder(speed: 15)
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func insideRadiusIsDue() {
        #expect(estimate(metresAway: 700, speed: nil).alarmReason == .insideRadius)
    }

    @Test func withinLeadTimeIsDue() {
        let estimate = estimate(metresAway: 1_700, speed: 15)

        #expect(estimate.speedSource == .measured)
        #expect(estimate.alarmReason == .withinLeadTime)
    }

    @Test func notDueWithoutMeasuredSpeed() {
        let estimate = estimate(metresAway: 1_000, speed: nil)

        #expect(estimate.speedSource == nil)
        #expect(estimate.alarmReason == nil)
        #expect(estimate.timeRemaining == nil)
    }

    @Test func notDueBeyondTheLeadDistance() throws {
        let estimate = estimate(metresAway: 3_000, speed: 15)

        #expect(estimate.alarmReason == nil)
        let timeRemaining = try #require(estimate.timeRemaining)
        #expect(abs(timeRemaining - 200) < 1)
    }

    @Test func alarmDistanceIsTheLargerOfLeadDistanceAndRadius() {
        #expect(estimate(metresAway: 5_000, speed: 3).alarmDistance == 750)
        #expect(estimate(metresAway: 5_000, speed: 20).alarmDistance == 2_400)
        #expect(estimate(metresAway: 5_000, speed: nil).alarmDistance == 750)
    }

    @Test func distanceIsPessimisticByAccuracy() {
        let far = estimate(metresAway: 1_000, speed: 15, accuracy: 150)
        let wifi = estimate(metresAway: 850, speed: nil, accuracy: 150)
        let close = estimate(metresAway: 100, speed: nil, accuracy: 150)

        #expect(far.distance == far.anchor.distance(to: route.destination(afterMetres: 1_000)) - 150)
        #expect(wifi.alarmReason == .insideRadius)
        #expect(close.distance == 0)
    }

    private func estimate(metresAway metres: Double, speed: Double?, accuracy: Double = 0) -> ArrivalEstimate {
        var anchor = route.sample(afterMetres: 0)
        anchor.horizontalAccuracy = accuracy
        return ArrivalEstimate(
            anchor: anchor,
            destination: route.destination(afterMetres: metres),
            cruiseSpeed: speed,
            isMoving: speed != nil,
            settings: settings
        )
    }
}
