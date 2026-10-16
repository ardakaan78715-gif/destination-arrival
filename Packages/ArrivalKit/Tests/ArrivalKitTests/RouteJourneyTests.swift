import ArrivalKit
import Foundation
import Testing

@Suite struct RouteJourneyTests {
    private let origin = Waypoint(latitude: 51.50, longitude: -0.30)

    @Test func stoppingServiceOnLiveGPSRingsAbout2MinutesEarly() throws {
        var route = RouteBuilder(from: origin)
        route.travel(eastward: 1_200, speed: 1_200 / 86)
        for _ in 2...7 {
            route.wait(40)
            route.travel(eastward: 1_200, speed: 1_200 / 86)
        }

        let outcome = RouteReplay.run(route.legs, to: route.position.destination())

        let early = try #require(outcome.secondsEarly)
        #expect((115...200).contains(early))
        #expect(outcome.reason == .withinLeadTime)
    }

    @Test func elizabethLineStationFixReanchors() throws {
        let route = undergroundLine(
            through: [.paddington, .bondStreet, .tottenhamCourtRoad, .farringdon, .liverpoolStreet, .whitechapel, .canaryWharf],
            runs: [120, 90, 120, 90, 90, 180],
            dwell: 45
        )
        let reachesFarringdon = try #require(route.legs.first { $0.to == .farringdon }?.end)
        let farringdonWiFi = Waypoint.farringdon.sample(accuracy: 65, at: reachesFarringdon + 10)
        let paddingtonWiFi = Waypoint.paddington.sample(accuracy: 65, at: route.legs[0].start)
        let canaryWharf = Waypoint.canaryWharf.destination(named: "Canary Wharf")

        let stationFix = RouteReplay.run(route.legs, to: canaryWharf, extraFixes: [farringdonWiFi])
        let boardingOnly = RouteReplay.run(route.legs, to: canaryWharf, extraFixes: [paddingtonWiFi])
        let reanchored = RouteReplay.run(route.legs, to: canaryWharf, extraFixes: [paddingtonWiFi, farringdonWiFi])

        let early = try #require(stationFix.secondsEarly)
        #expect((110...330).contains(early))
        #expect(reanchored.ringTime == stationFix.ringTime)
        let boardingRing = try #require(boardingOnly.ringTime)
        let reanchoredRing = try #require(reanchored.ringTime)
        #expect(boardingRing < reanchoredRing)
    }

    @Test func victoriaLineUndergroundStartRingsEarly() throws {
        let route = undergroundLine(
            through: [.brixton, .stockwell, .vauxhall, .pimlico, .victoria, .greenPark, .oxfordCircus],
            runs: [120, 120, 90, 100, 100, 90],
            dwell: 30
        )
        let brixtonWiFi = Waypoint.brixton.sample(accuracy: 65, at: route.legs[0].start)

        let outcome = RouteReplay.run(
            route.legs,
            to: Waypoint.oxfordCircus.destination(named: "Oxford Circus"),
            extraFixes: [brixtonWiFi]
        )

        let early = try #require(outcome.secondsEarly)
        #expect(early >= 110)
        #expect(outcome.reason == .projectedDuringSignalLoss)
    }

    @Test func trainHeldInTunnelStillRingsEarly() throws {
        var route = RouteBuilder(from: origin)
        route.wait(60)
        route.travel(eastward: 1_500, speed: 15)
        route.wait(40)
        route.travel(eastward: 1_500, speed: 15, underground: true)
        route.wait(180, underground: true)
        route.travel(eastward: 1_500, speed: 15, underground: true)
        route.travel(eastward: 1_500, speed: 15, underground: true)

        let outcome = RouteReplay.run(route.legs, to: route.position.destination())

        #expect(outcome.arrival == FixBuilder.startDate + 680)
        let early = try #require(outcome.secondsEarly)
        #expect(early >= 110)
    }

    @Test func stationaryJourneyNeverRings() {
        var route = RouteBuilder(from: origin)
        route.wait(1_800)

        let outcome = RouteReplay.run(route.legs, to: origin.moved(eastMetres: 5_000).destination())

        #expect(outcome.ringTime == nil)
    }

    private func undergroundLine(through stations: [Waypoint], runs: [TimeInterval], dwell: TimeInterval) -> RouteBuilder {
        var route = RouteBuilder(from: stations[0])
        route.wait(60, underground: true)
        for (index, run) in runs.enumerated() {
            if index > 0 {
                route.wait(dwell, underground: true)
            }
            route.travel(to: stations[index + 1], seconds: run, underground: true)
        }
        return route
    }
}

private extension Waypoint {
    static let brixton = Waypoint(latitude: 51.4627, longitude: -0.1145)
    static let stockwell = Waypoint(latitude: 51.4723, longitude: -0.1229)
    static let vauxhall = Waypoint(latitude: 51.4861, longitude: -0.1253)
    static let pimlico = Waypoint(latitude: 51.4893, longitude: -0.1334)
    static let victoria = Waypoint(latitude: 51.4965, longitude: -0.1447)
    static let greenPark = Waypoint(latitude: 51.5067, longitude: -0.1428)
    static let oxfordCircus = Waypoint(latitude: 51.5152, longitude: -0.1419)

    static let paddington = Waypoint(latitude: 51.5154, longitude: -0.1755)
    static let bondStreet = Waypoint(latitude: 51.5142, longitude: -0.1494)
    static let tottenhamCourtRoad = Waypoint(latitude: 51.5165, longitude: -0.1310)
    static let farringdon = Waypoint(latitude: 51.5203, longitude: -0.1053)
    static let liverpoolStreet = Waypoint(latitude: 51.5178, longitude: -0.0823)
    static let whitechapel = Waypoint(latitude: 51.5195, longitude: -0.0596)
    static let canaryWharf = Waypoint(latitude: 51.5058, longitude: -0.0172)
}
