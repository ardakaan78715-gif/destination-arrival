import ArrivalKit
import Foundation
import Testing

@Suite struct ArrivalEstimateTests {
    private let route = FixBuilder(speed: 15)
    private let settings = AlarmSettings(leadTime: 120, radius: 750)
    private let anchorTime = FixBuilder.startDate

    @Test func insideRadiusIsDue() {
        #expect(estimate(metresAway: 700, speed: nil).alarmReason(at: anchorTime) == .insideRadius)
    }

    @Test func withinLeadTimeIsDue() {
        let estimate = estimate(metresAway: 1_700, speed: 15)

        #expect(estimate.speedSource == .measured)
        #expect(estimate.alarmReason(at: anchorTime) == .withinLeadTime)
    }

    @Test func notDueWithoutMeasuredSpeed() {
        let estimate = estimate(metresAway: 1_000, speed: nil)

        #expect(estimate.speedSource == .assumed)
        #expect(estimate.speed == 15)
        #expect(estimate.alarmReason(at: anchorTime) == nil)
    }

    @Test func notDueBeyondTheLeadDistance() {
        let estimate = estimate(metresAway: 3_000, speed: 15)

        #expect(estimate.alarmReason(at: anchorTime) == nil)
        #expect(abs(estimate.timeRemaining(at: anchorTime) - 200) < 1)
    }

    @Test func alarmDistanceIsTheLargerOfLeadDistanceAndRadius() {
        #expect(estimate(metresAway: 5_000, speed: 3).alarmDistance == 750)
        #expect(estimate(metresAway: 5_000, speed: 20).alarmDistance == 2_400)
        #expect(estimate(metresAway: 5_000, speed: nil).alarmDistance == 1_800)
    }

    @Test func distanceIsPessimisticByAccuracy() {
        let far = estimate(metresAway: 1_000, speed: 15, accuracy: 150)
        let wifi = estimate(metresAway: 850, speed: nil, accuracy: 150)
        let close = estimate(metresAway: 100, speed: nil, accuracy: 150)

        #expect(far.distance == far.anchor.distance(to: route.destination(afterMetres: 1_000)) - 150)
        #expect(wifi.alarmReason(at: anchorTime) == .insideRadius)
        #expect(close.distance == 0)
    }

    @Test func projectionAdvancesAtCautiousSpeed() {
        let estimate = estimate(metresAway: 5_000, speed: 20)
        let tenSecondsOn = estimate.distance - 220

        #expect(abs(estimate.projectionSpeed - 22) < 0.001)
        #expect(estimate.distanceRemaining(at: anchorTime) == estimate.distance)
        #expect(abs(estimate.distanceRemaining(at: anchorTime + 10) - tenSecondsOn) < 0.001)
        #expect(abs(estimate.timeRemaining(at: anchorTime + 10) - tenSecondsOn / 20) < 0.001)
        #expect(estimate.distanceRemaining(at: anchorTime - 30) == estimate.distance)
        #expect(estimate.distanceRemaining(at: anchorTime + 3_600) == 0)
    }

    @Test func projectionNeverSlowerThanFastTrainSpeed() {
        let slow = estimate(metresAway: 5_000, speed: 5)
        let assumed = estimate(metresAway: 5_000, speed: nil)

        #expect(slow.projectionSpeed == 15)
        #expect(abs(slow.distanceRemaining(at: anchorTime + 10) - (slow.distance - 150)) < 0.001)
        #expect(abs(assumed.projectionSpeed - 16.5) < 0.001)
    }

    @Test func alarmDateMatchesFormula() {
        let destination = route.destination(afterMetres: 3_100)
        var anchor = route.sample(afterMetres: 0)
        anchor.horizontalAccuracy = anchor.distance(to: destination) - 3_000
        let estimate = ArrivalEstimate(
            anchor: anchor,
            destination: destination,
            cruiseSpeed: 20,
            isMoving: true,
            settings: settings
        )

        #expect(abs(estimate.distance - 3_000) < 0.001)
        #expect(abs(estimate.alarmDate.timeIntervalSince(anchorTime) - 27.27) < 0.01)
        #expect(self.estimate(metresAway: 2_000, speed: 20).alarmDate == anchorTime)
    }

    @Test func dueAtFixTimeMeansWithinLeadOrRadius() {
        for speed in [5.0, 10, 15, 20, 25] {
            for metres in stride(from: 250.0, through: 4_000, by: 125) {
                let estimate = estimate(metresAway: metres, speed: speed)
                let withinLead = estimate.distance / speed <= settings.leadTime
                let insideRadius = estimate.distance <= settings.radius

                #expect((estimate.alarmReason(at: anchorTime) != nil) == (withinLead || insideRadius))
            }
        }
    }

    @Test func signalLostAfter45Seconds() {
        let estimate = estimate(metresAway: 5_000, speed: 15)

        #expect(!estimate.isSignalLost(at: anchorTime))
        #expect(!estimate.isSignalLost(at: anchorTime + 45))
        #expect(estimate.isSignalLost(at: anchorTime + 46))
    }

    @Test func assumedSpeedArmsOnlyAfterSignalLoss() {
        let assumed = estimate(metresAway: 2_000, speed: nil)
        let measured = estimate(metresAway: 2_000, speed: 15)

        #expect(!assumed.isArmed(at: anchorTime + 30))
        #expect(assumed.alarmReason(at: anchorTime + 30) == nil)
        #expect(assumed.isArmed(at: anchorTime + 46))
        #expect(assumed.alarmReason(at: anchorTime + 46) == .projectedDuringSignalLoss)
        #expect(measured.isArmed(at: anchorTime))
        #expect(measured.alarmReason(at: anchorTime + 30) == .withinLeadTime)
    }

    @Test func statusCoversLiveStoppedWaitingAndEstimating() {
        let moving = estimate(metresAway: 5_000, speed: 15)
        let stopped = estimate(metresAway: 5_000, speed: 15, isMoving: false)
        let waiting = estimate(metresAway: 5_000, speed: nil, isMoving: false)

        #expect(moving.signalStatus(at: anchorTime + 10) == .live)
        #expect(stopped.signalStatus(at: anchorTime + 10) == .stopped)
        #expect(waiting.signalStatus(at: anchorTime + 10) == .waitingToMove)
        #expect(moving.signalStatus(at: anchorTime + 46) == .estimating(since: anchorTime))
        #expect(waiting.signalStatus(at: anchorTime + 46) == .estimating(since: anchorTime))
    }

    private func estimate(
        metresAway metres: Double,
        speed: Double?,
        accuracy: Double = 0,
        isMoving: Bool = true
    ) -> ArrivalEstimate {
        var anchor = route.sample(afterMetres: 0)
        anchor.horizontalAccuracy = accuracy
        return ArrivalEstimate(
            anchor: anchor,
            destination: route.destination(afterMetres: metres),
            cruiseSpeed: speed,
            isMoving: isMoving,
            settings: settings
        )
    }
}
