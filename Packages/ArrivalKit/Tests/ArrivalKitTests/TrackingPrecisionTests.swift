import ArrivalKit
import Foundation
import Testing

@Suite struct TrackingPrecisionTests {
    private let settings = AlarmSettings(leadTime: 120, radius: 750)

    @Test func startsInEconomy() {
        let train = FixBuilder(speed: 15, count: 60)
        var journey = Journey(destination: train.destination(afterMetres: 20_000), settings: settings)

        #expect(journey.precision == .economy)
        #expect(journey.handle(.started(FixBuilder.startDate)) == [.startLocationUpdates(.economy)])
        #expect(train.samples().flatMap { journey.handle(.locationReceived($0)) }.isEmpty)
        #expect(journey.precision == .economy)
    }

    @Test func upgradesWithinFiveKilometres() throws {
        let bus = FixBuilder(speed: 5, count: 1_600)
        var journey = startedJourney(to: bus.destination(afterMetres: 12_000))

        let estimate = try #require(estimateAtUpgrade(feeding: bus.samples(), to: &journey))
        let anchorTime = estimate.anchor.timestamp

        #expect(estimate.distanceRemaining(at: anchorTime) <= 5_000)
        #expect(estimate.distanceRemaining(at: anchorTime) > 4_980)
        #expect(estimate.timeRemaining(at: anchorTime) > 600)
        #expect(journey.precision == .precise)
    }

    @Test func upgradesWithinTenMinutes() throws {
        let train = FixBuilder(speed: 20, count: 900)
        var journey = startedJourney(to: train.destination(afterMetres: 25_000))

        let estimate = try #require(estimateAtUpgrade(feeding: train.samples(), to: &journey))
        let anchorTime = estimate.anchor.timestamp

        #expect(estimate.timeRemaining(at: anchorTime) <= 600)
        #expect(estimate.timeRemaining(at: anchorTime) > 595)
        #expect(estimate.distanceRemaining(at: anchorTime) > 5_000)
        #expect(journey.precision == .precise)
    }

    @Test func upgradesOnTheProjectionInATunnel() throws {
        let train = FixBuilder(speed: 15, count: 60)
        var journey = startedJourney(to: train.destination(afterMetres: 12_000))
        let fixEffects = train.samples().flatMap { journey.handle(.locationReceived($0)) }
        let estimate = try #require(journey.estimate)

        let ticks = stride(from: 10.0, through: 300, by: 10).map { estimate.anchor.timestamp + $0 }
        let tickEffects = ticks.map { journey.handle(.clockTicked($0)) }
        let upgrade = ticks[try #require(tickEffects.firstIndex(of: [.changePrecision(.precise)]))]

        #expect(fixEffects.isEmpty)
        #expect(tickEffects.flatMap { $0 } == [.changePrecision(.precise)])
        #expect(estimate.isSignalLost(at: upgrade))
        #expect(estimate.timeRemaining(at: upgrade) <= 600)
        #expect(estimate.timeRemaining(at: upgrade - 10) > 600)
        #expect(journey.phase == .tracking)
    }

    @Test func neverDowngrades() throws {
        let bus = FixBuilder(speed: 5, count: 120)
        var journey = startedJourney(to: bus.destination(afterMetres: 8_000))

        let effects = bus.samples().map { journey.handle(.locationReceived($0)) }
        let estimate = try #require(journey.estimate)

        #expect(effects.first == [.changePrecision(.precise)])
        #expect(effects.flatMap { $0 } == [.changePrecision(.precise)])
        #expect(estimate.speedSource == .measured)
        #expect(TrackingPrecision.required(for: estimate, at: estimate.anchor.timestamp) == .economy)
        #expect(journey.precision == .precise)
    }

    @Test func emitsChangeOnlyOnce() {
        let train = FixBuilder(speed: 20, count: 700)
        var journey = startedJourney(to: train.destination(afterMetres: 14_000))

        var effects: [JourneyEffect] = []
        for fix in train.samples() {
            effects += journey.handle(.locationReceived(fix))
            effects += journey.handle(.clockTicked(fix.timestamp + 0.5))
        }

        #expect(effects.filter { $0 == .changePrecision(.precise) }.count == 1)
        #expect(!effects.contains(.changePrecision(.economy)))
        #expect(effects.contains(.ringAlarm(.withinLeadTime)))
    }

    private func startedJourney(to destination: Destination) -> Journey {
        var journey = Journey(destination: destination, settings: settings)
        _ = journey.handle(.started(FixBuilder.startDate))
        return journey
    }

    private func estimateAtUpgrade(feeding samples: [LocationSample], to journey: inout Journey) -> ArrivalEstimate? {
        for sample in samples {
            if journey.handle(.locationReceived(sample)) == [.changePrecision(.precise)] {
                return journey.estimate
            }
        }
        return nil
    }
}
