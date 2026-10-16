import ArrivalKit
import Testing

@Suite struct JourneyTests {
    private let route = FixBuilder(speed: 15, count: 600)
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func startEmitsLocationUpdates() {
        var journey = Journey(destination: route.destination(afterMetres: 5_000), settings: settings)

        #expect(journey.handle(.started(FixBuilder.startDate)) == [.startLocationUpdates])
        #expect(journey.phase == .tracking)
    }

    @Test func ringsInsideRadius() {
        var journey = startedJourney(metresAway: 5_000)
        let nearby = route.sample(afterMetres: 4_400, elapsed: 300)

        #expect(journey.handle(.locationReceived(nearby)) == [.stopLocationUpdates, .ringAlarm(.insideRadius)])
        #expect(journey.phase == .ringing(.insideRadius))
    }

    @Test func ringsWithinLeadTime() throws {
        var journey = startedJourney(metresAway: 3_000)

        let effects = firstEffects(feeding: route.samples(), to: &journey)

        #expect(effects == [.stopLocationUpdates, .ringAlarm(.withinLeadTime)])
        let timeRemaining = try #require(journey.estimate?.timeRemaining)
        #expect(timeRemaining <= 120)
        #expect(timeRemaining > 115)
    }

    @Test func ringsExactlyOnce() {
        var journey = startedJourney(metresAway: 3_000)
        _ = firstEffects(feeding: route.samples(), to: &journey)
        let phase = journey.phase

        let later = route.samples().flatMap { journey.handle(.locationReceived($0)) }

        #expect(later.isEmpty)
        #expect(journey.phase == phase)
    }

    @Test func stopSilencesAndFinishes() {
        var journey = startedJourney(metresAway: 3_000)
        _ = firstEffects(feeding: route.samples(), to: &journey)

        #expect(journey.handle(.alarmStopped) == [.silenceAlarm])
        #expect(journey.phase == .finished)
        #expect(journey.handle(.alarmStopped).isEmpty)
    }

    @Test func cancelWhileRingingSilences() {
        var journey = startedJourney(metresAway: 3_000)
        _ = firstEffects(feeding: route.samples(), to: &journey)

        #expect(journey.handle(.cancelled) == [.silenceAlarm])
        #expect(journey.phase == .finished)
    }

    @Test func cancelStopsTracking() {
        var journey = startedJourney(metresAway: 3_000)

        #expect(journey.handle(.cancelled) == [.stopLocationUpdates])
        #expect(journey.phase == .finished)
        #expect(firstEffects(feeding: route.samples(), to: &journey).isEmpty)
    }

    @Test func ignoresEventsBeforeStart() {
        var journey = Journey(destination: route.destination(afterMetres: 100), settings: settings)

        #expect(journey.handle(.locationReceived(route.samples()[0])).isEmpty)
        #expect(journey.handle(.alarmStopped).isEmpty)
        #expect(journey.handle(.cancelled).isEmpty)
        #expect(journey.phase == .ready)
        #expect(journey.estimate == nil)
    }

    @Test func standingStillFarAwayNeverRings() {
        var journey = startedJourney(metresAway: 5_000)
        let platform = FixBuilder(speed: 0, count: 1_800)

        #expect(firstEffects(feeding: platform.samples(), to: &journey).isEmpty)
        #expect(journey.phase == .tracking)
    }

    private func startedJourney(metresAway metres: Double) -> Journey {
        var journey = Journey(destination: route.destination(afterMetres: metres), settings: settings)
        _ = journey.handle(.started(FixBuilder.startDate))
        return journey
    }

    private func firstEffects(feeding samples: [LocationSample], to journey: inout Journey) -> [JourneyEffect] {
        for sample in samples {
            let effects = journey.handle(.locationReceived(sample))
            if !effects.isEmpty {
                return effects
            }
        }
        return []
    }
}
