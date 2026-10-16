import ArrivalKit
import Testing

@Suite struct JourneyTests {
    private let route = FixBuilder(speed: 15, count: 600)
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func startEmitsLocationUpdates() {
        var journey = Journey(destination: route.destination(afterMetres: 5_000), settings: settings)

        #expect(journey.handle(.started(FixBuilder.startDate)) == [.startLocationUpdates(.economy)])
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

        let effects = ringingEffects(feeding: route.samples(), to: &journey)

        #expect(effects == [.stopLocationUpdates, .ringAlarm(.withinLeadTime)])
        let estimate = try #require(journey.estimate)
        #expect(estimate.isMoving)
        let timeRemaining = estimate.timeRemaining(at: estimate.anchor.timestamp)
        #expect(timeRemaining <= 120)
        #expect(timeRemaining > 115)
    }

    @Test func ringsExactlyOnce() {
        var journey = startedJourney(metresAway: 3_000)
        _ = ringingEffects(feeding: route.samples(), to: &journey)
        let phase = journey.phase

        let later = route.samples().flatMap { journey.handle(.locationReceived($0)) }

        #expect(later.isEmpty)
        #expect(journey.phase == phase)
    }

    @Test func stopSilencesAndFinishes() {
        var journey = startedJourney(metresAway: 3_000)
        _ = ringingEffects(feeding: route.samples(), to: &journey)

        #expect(journey.handle(.alarmStopped) == [.silenceAlarm])
        #expect(journey.phase == .finished)
        #expect(journey.handle(.alarmStopped).isEmpty)
    }

    @Test func cancelWhileRingingSilences() {
        var journey = startedJourney(metresAway: 3_000)
        _ = ringingEffects(feeding: route.samples(), to: &journey)

        #expect(journey.handle(.cancelled) == [.silenceAlarm])
        #expect(journey.phase == .finished)
    }

    @Test func cancelStopsTracking() {
        var journey = startedJourney(metresAway: 3_000)

        #expect(journey.handle(.cancelled) == [.stopLocationUpdates])
        #expect(journey.phase == .finished)
        #expect(route.samples().flatMap { journey.handle(.locationReceived($0)) }.isEmpty)
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

        #expect(ringingEffects(feeding: platform.samples(), to: &journey).isEmpty)
        #expect(journey.phase == .tracking)
        #expect(journey.estimate?.isMoving == false)
    }

    @Test func staleFixesFromBeforeStartAreIgnored() {
        var journey = startedJourney(metresAway: 5_000)
        let cachedBeforeStart = route.sample(afterMetres: 4_900, elapsed: -120)

        #expect(journey.handle(.locationReceived(cachedBeforeStart)).isEmpty)
        #expect(journey.estimate == nil)
        #expect(journey.phase == .tracking)
    }

    @Test func rejectedFixesAreIgnored() {
        var journey = startedJourney(metresAway: 5_000)
        _ = journey.handle(.locationReceived(route.sample(afterMetres: 0)))
        let estimate = journey.estimate
        var cellTower = route.sample(afterMetres: 4_800, elapsed: 400)
        cellTower.horizontalAccuracy = 500
        let glitch = route.sample(afterMetres: 4_900, elapsed: 2)

        for fix in [cellTower, glitch] {
            #expect(journey.handle(.locationReceived(fix)).isEmpty)
        }
        #expect(journey.estimate == estimate)
        #expect(journey.phase == .tracking)
    }

    @Test func coarseStationFixCountsForDistance() {
        var journey = startedJourney(metresAway: 5_000)
        _ = journey.handle(.locationReceived(route.sample(afterMetres: 0)))
        var stationWiFi = route.sample(afterMetres: 4_150, elapsed: 300)
        stationWiFi.horizontalAccuracy = 150

        #expect(journey.handle(.locationReceived(stationWiFi)) == [.stopLocationUpdates, .ringAlarm(.insideRadius)])
        #expect(journey.estimate?.speedSource == .assumed)
    }

    @Test func jitterOutsideRadiusNeverRings() {
        var journey = startedJourney(metresAway: 1_500)
        let platform = FixBuilder(speed: 0, count: 1_800).jittered(maxMetres: 8, seed: 3)

        #expect(ringingEffects(feeding: platform.samples(), to: &journey).isEmpty)
        #expect(journey.phase == .tracking)
        #expect(journey.estimate?.speedSource == .assumed)
    }

    private func startedJourney(metresAway metres: Double) -> Journey {
        var journey = Journey(destination: route.destination(afterMetres: metres), settings: settings)
        _ = journey.handle(.started(FixBuilder.startDate))
        return journey
    }

    private func ringingEffects(feeding samples: [LocationSample], to journey: inout Journey) -> [JourneyEffect] {
        for sample in samples {
            let effects = journey.handle(.locationReceived(sample))
            if case .ringing = journey.phase {
                return effects
            }
        }
        return []
    }
}
