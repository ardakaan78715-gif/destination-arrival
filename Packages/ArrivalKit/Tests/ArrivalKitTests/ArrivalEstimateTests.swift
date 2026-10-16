import ArrivalKit
import Testing

@Suite struct ArrivalEstimateTests {
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func insideRadiusIsDue() {
        let estimate = ArrivalEstimate(distance: 700, speed: nil, settings: settings)

        #expect(estimate.alarmReason == .insideRadius)
    }

    @Test func withinLeadTimeIsDue() {
        let estimate = ArrivalEstimate(distance: 1_700, speed: 15, settings: settings)

        #expect(estimate.alarmReason == .withinLeadTime)
    }

    @Test func notDueWithoutSpeed() {
        let estimate = ArrivalEstimate(distance: 1_000, speed: nil, settings: settings)

        #expect(estimate.alarmReason == nil)
        #expect(estimate.timeRemaining == nil)
    }

    @Test func notDueBeyondTheLeadDistance() {
        let estimate = ArrivalEstimate(distance: 3_000, speed: 15, settings: settings)

        #expect(estimate.alarmReason == nil)
        #expect(estimate.timeRemaining == 200)
    }

    @Test func alarmDistanceIsTheLargerOfLeadDistanceAndRadius() {
        #expect(ArrivalEstimate(distance: 5_000, speed: 3, settings: settings).alarmDistance == 750)
        #expect(ArrivalEstimate(distance: 5_000, speed: 20, settings: settings).alarmDistance == 2_400)
        #expect(ArrivalEstimate(distance: 5_000, speed: nil, settings: settings).alarmDistance == 750)
    }
}
