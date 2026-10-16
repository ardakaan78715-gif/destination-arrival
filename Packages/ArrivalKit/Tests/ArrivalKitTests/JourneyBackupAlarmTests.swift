import ArrivalKit
import Foundation
import Testing

@Suite struct JourneyBackupAlarmTests {
    private let run = FixBuilder(speed: 15, count: 61)
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func schedulesBackupOnceArmed() throws {
        var journey = startedJourney(metresAway: 20_000)
        var effectsBeforeArming: [JourneyEffect] = []
        var armingEffects: [JourneyEffect] = []
        for fix in run.samples() {
            let effects = journey.handle(.locationReceived(fix))
            if journey.estimate?.speedSource == .measured {
                armingEffects = effects
                break
            }
            effectsBeforeArming += effects
        }
        let estimate = try #require(journey.estimate)
        let laterFixes = run.samples().filter { $0.timestamp > estimate.anchor.timestamp }

        #expect(estimate.speedSource == .measured)
        #expect(effectsBeforeArming.isEmpty)
        #expect(armingEffects == [.scheduleBackupAlarm(estimate.alarmDate)])
        #expect(journey.scheduledBackup == estimate.alarmDate)
        #expect(!laterFixes.isEmpty)
        #expect(laterFixes.flatMap { journey.handle(.locationReceived($0)) }.isEmpty)
    }

    @Test func noBackupWhileWaitingWithLiveGPS() {
        var journey = startedJourney(metresAway: 1_500)
        let platform = FixBuilder(speed: 0, count: 1_800).jittered(maxMetres: 8, seed: 7)

        var effects: [JourneyEffect] = []
        for fix in platform.samples() {
            effects += journey.handle(.locationReceived(fix))
            effects += journey.handle(.clockTicked(fix.timestamp + 0.5))
        }

        #expect(effects == [.changePrecision(.precise)])
        #expect(journey.scheduledBackup == nil)
        #expect(journey.estimate?.speedSource == .assumed)
    }

    @Test func signalLossSchedulesBackupBeforeSpeedIsMeasured() throws {
        var journey = startedJourney(metresAway: 8_000)
        _ = journey.handle(.locationReceived(run.samples()[0]))
        let estimate = try #require(journey.estimate)
        let lastFix = estimate.anchor.timestamp

        #expect(estimate.speedSource == .assumed)
        #expect(journey.handle(.clockTicked(lastFix + 40)).isEmpty)
        #expect(journey.handle(.clockTicked(lastFix + 50)) == [.scheduleBackupAlarm(estimate.alarmDate)])
        #expect(journey.scheduledBackup == estimate.alarmDate)
    }

    @Test func reschedulesOnlyWhenDateMovesMoreThan20Seconds() throws {
        var journey = journeyAfterRun(metresAway: 6_000)
        let firstBackup = try #require(journey.scheduledBackup)
        let lastFix = try #require(journey.estimate?.anchor)

        #expect(journey.handle(.locationReceived(held(lastFix, for: 10))).isEmpty)
        let slightlyLater = try #require(journey.estimate?.alarmDate)
        #expect(slightlyLater > firstBackup)
        #expect(slightlyLater.timeIntervalSince(firstBackup) <= 20)
        #expect(journey.scheduledBackup == firstBackup)

        let effects = journey.handle(.locationReceived(held(lastFix, for: 30)))
        let muchLater = try #require(journey.estimate?.alarmDate)
        #expect(muchLater.timeIntervalSince(firstBackup) > 20)
        #expect(effects == [.scheduleBackupAlarm(muchLater)])
        #expect(journey.scheduledBackup == muchLater)
    }

    @Test func ringCancelsScheduledBackup() throws {
        var journey = journeyAfterRun(metresAway: 3_000)
        let estimate = try #require(journey.estimate)
        #expect(journey.scheduledBackup != nil)

        #expect(journey.handle(.clockTicked(estimate.alarmDate)) == [
            .stopLocationUpdates,
            .cancelBackupAlarm,
            .ringAlarm(.withinLeadTime),
        ])
        #expect(journey.scheduledBackup == nil)
    }

    @Test func cancelCancelsScheduledBackup() {
        var journey = journeyAfterRun(metresAway: 6_000)
        #expect(journey.scheduledBackup != nil)

        #expect(journey.handle(.cancelled) == [.stopLocationUpdates, .cancelBackupAlarm])
        #expect(journey.scheduledBackup == nil)
        #expect(journey.phase == .finished)
    }

    @Test func backupFiredRingsWithScheduledBackupReason() {
        var journey = journeyAfterRun(metresAway: 6_000)

        #expect(journey.handle(.backupAlarmFired) == [
            .stopLocationUpdates,
            .cancelBackupAlarm,
            .ringAlarm(.scheduledBackup),
        ])
        #expect(journey.phase == .ringing(.scheduledBackup))
        #expect(journey.handle(.alarmStopped) == [.silenceAlarm])
        #expect(journey.phase == .finished)
    }

    @Test func backupFiredAfterRingIsIgnored() throws {
        var journey = journeyAfterRun(metresAway: 3_000)
        let estimate = try #require(journey.estimate)
        _ = journey.handle(.clockTicked(estimate.alarmDate))

        #expect(journey.handle(.backupAlarmFired).isEmpty)
        #expect(journey.phase == .ringing(.withinLeadTime))

        _ = journey.handle(.alarmStopped)
        #expect(journey.handle(.backupAlarmFired).isEmpty)
        #expect(journey.phase == .finished)
    }

    @Test func backupFiredBeforeStartIsIgnored() {
        var journey = Journey(destination: run.destination(afterMetres: 6_000), settings: settings)

        #expect(journey.handle(.backupAlarmFired).isEmpty)
        #expect(journey.phase == .ready)
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

    private func held(_ fix: LocationSample, for seconds: TimeInterval) -> LocationSample {
        var held = fix
        held.timestamp += seconds
        return held
    }
}
