import ArrivalKit
import Foundation
import Testing

@Suite struct MetropolitanLineReplayTests {
    private static let finchleyRoadArrival = 14

    private let toBakerStreet: GPXRoute
    private let toFinchleyRoad: GPXRoute

    init() throws {
        toBakerStreet = try GPXRoute.load("MetropolitanLine")
        toFinchleyRoad = toBakerStreet.prefix(Self.finchleyRoadArrival)
    }

    @Test func ringsInTunnelBeforeBakerStreet() throws {
        let outcome = try replay(toBakerStreet)

        let early = try #require(outcome.secondsEarly)
        #expect((110...300).contains(early))
        #expect(outcome.reason == .projectedDuringSignalLoss)
    }

    @Test func ringsBeforeFinchleyRoadOnLiveGPS() throws {
        let outcome = try replay(toFinchleyRoad)

        let early = try #require(outcome.secondsEarly)
        #expect((110...200).contains(early))
        #expect(outcome.reason == .withinLeadTime)
    }

    @Test func outcomeIsStableAcrossJitterSeeds() throws {
        for route in [toBakerStreet, toFinchleyRoad] {
            let ringTimes = try (1...5).map { seed in
                let outcome = try replay(route, seed: UInt64(seed))
                return try #require(outcome.ringTime)
            }

            let earliest = try #require(ringTimes.min())
            let latest = try #require(ringTimes.max())
            #expect(latest.timeIntervalSince(earliest) <= 5, "\(route.destination?.name ?? "")")
        }
    }

    private func replay(_ route: GPXRoute, seed: UInt64 = 1) throws -> ReplayOutcome {
        let destination = try #require(route.destination)
        return RouteReplay.run(route.legs, to: destination, seed: seed)
    }
}
