import ArrivalKit
import Foundation
import Testing

@Suite struct JourneySignalLossTests {
    private let run = FixBuilder(speed: 15, count: 60)
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func tickRingsWhenProjectionIsDue() throws {
        var journey = journeyAfterRun(metresAway: 5_000)
        let estimate = try #require(journey.estimate)

        #expect(estimate.speedSource == .measured)
        #expect(journey.handle(.clockTicked(estimate.alarmDate - 1)).isEmpty)
        #expect(journey.handle(.clockTicked(estimate.alarmDate)) == [
            .stopLocationUpdates,
            .ringAlarm(.projectedDuringSignalLoss),
        ])
    }

    @Test func ticksNeverRingWhileWaitingWithLiveGPS() {
        var journey = startedJourney(metresAway: 1_500)
        let platform = FixBuilder(speed: 0, count: 1_800).jittered(maxMetres: 8, seed: 5)

        var effects: [JourneyEffect] = []
        for fix in platform.samples() {
            effects += journey.handle(.locationReceived(fix))
            effects += journey.handle(.clockTicked(fix.timestamp + 0.5))
        }

        #expect(effects.isEmpty)
        #expect(journey.phase == .tracking)
        #expect(journey.estimate?.speedSource == .assumed)
    }

    @Test func freshFixAfterHoldPushesAlarmBack() throws {
        var journey = journeyAfterRun(metresAway: 5_000)
        let lastFix = try #require(journey.estimate?.anchor)
        let projected = try #require(journey.estimate?.alarmDate)
        let heldFor: TimeInterval = 120
        let lastElapsed = lastFix.timestamp.timeIntervalSince(run.start)

        for seconds in stride(from: 10.0, to: heldFor, by: 10) {
            #expect(journey.handle(.clockTicked(lastFix.timestamp + seconds)).isEmpty)
        }
        let afterHold = run.sample(afterMetres: run.travelled(after: lastElapsed) + 450, elapsed: lastElapsed + heldFor)
        #expect(journey.handle(.locationReceived(afterHold)).isEmpty)

        let rescheduled = try #require(journey.estimate?.alarmDate)
        #expect(rescheduled.timeIntervalSince(projected) > 60)
        #expect(journey.handle(.clockTicked(projected + 1)).isEmpty)
        #expect(journey.phase == .tracking)
    }

    @Test func reasonIsProjectedDuringSignalLoss() throws {
        var journey = journeyAfterRun(metresAway: 5_000)
        let estimate = try #require(journey.estimate)

        _ = journey.handle(.clockTicked(estimate.alarmDate))

        #expect(estimate.isSignalLost(at: estimate.alarmDate))
        #expect(journey.phase == .ringing(.projectedDuringSignalLoss))
    }

    @Test func projectionDueBeforeSignalLossIsWithinLeadTime() throws {
        var journey = journeyAfterRun(metresAway: 3_000)
        let estimate = try #require(journey.estimate)

        _ = journey.handle(.clockTicked(estimate.alarmDate))

        #expect(!estimate.isSignalLost(at: estimate.alarmDate))
        #expect(journey.phase == .ringing(.withinLeadTime))
    }

    @Test func ticksBeforeTheFirstFixDoNothing() {
        var journey = startedJourney(metresAway: 500)

        #expect(journey.handle(.clockTicked(FixBuilder.startDate + 600)).isEmpty)
        #expect(journey.phase == .tracking)
        #expect(journey.estimate == nil)
    }

    @Test func ticksBeforeStartAndAfterRingAreIgnored() {
        var journey = Journey(destination: run.destination(afterMetres: 500), settings: settings)

        #expect(journey.handle(.clockTicked(FixBuilder.startDate)).isEmpty)
        #expect(journey.phase == .ready)

        _ = journey.handle(.started(FixBuilder.startDate))
        _ = journey.handle(.locationReceived(run.samples()[0]))
        #expect(journey.phase == .ringing(.insideRadius))
        #expect(journey.handle(.clockTicked(FixBuilder.startDate + 600)).isEmpty)
        #expect(journey.phase == .ringing(.insideRadius))

        _ = journey.handle(.alarmStopped)
        #expect(journey.handle(.clockTicked(FixBuilder.startDate + 1_200)).isEmpty)
        #expect(journey.phase == .finished)
    }

    private func startedJourney(metresAway metres: Double) -> Journey {
        var journey = Journey(destination: run.destination(afterMetres: metres), settings: settings)
        _ = journey.handle(.started(FixBuilder.startDate))
        return journey
    }

    private func journeyAfterRun(metresAway metres: Double) -> Journey {
        var journey = startedJourney(metresAway: metres)
        for fix in run.samples() {
            _ = journey.handle(.locationReceived(fix))
        }
        return journey
    }
}
