import ArrivalKit
import Foundation
import Testing

@Suite struct GPXRouteTests {
    private let route: GPXRoute

    init() throws {
        route = try GPXRoute.load("MetropolitanLine")
    }

    @Test func parsesNineteenWaypoints() {
        #expect(route.waypoints.count == 19)
        #expect(route.legs.count == 18)
    }

    @Test func startsAtHarrowAndEndsAtBakerStreet() throws {
        let first = try #require(route.waypoints.first)
        let last = try #require(route.waypoints.last)

        #expect(first.name == "Harrow-on-the-Hill")
        #expect(first.position == Waypoint(latitude: 51.5793, longitude: -0.3366))
        #expect(first.time == Self.date("2026-01-05T07:58:30Z"))
        #expect(last.name == "Baker Street")
        #expect(last.position == Waypoint(latitude: 51.5226, longitude: -0.1571))
        #expect(last.time == Self.date("2026-01-05T08:17:46Z"))
    }

    @Test func tunnelStartsAtFinchleyRoad() throws {
        let firstTunnel = try #require(route.legs.firstIndex { $0.isUnderground })

        #expect(route.waypoints[firstTunnel].name == "Finchley Road")
        #expect(route.waypoints[firstTunnel].time == Self.date("2026-01-05T08:13:46Z"))
        #expect(route.legs[..<firstTunnel].allSatisfy { !$0.isUnderground })
        #expect(route.legs[firstTunnel...].allSatisfy { $0.isUnderground })
    }

    @Test func timesStrictlyIncreaseOrHoldAtStations() {
        for (from, to) in zip(route.waypoints, route.waypoints.dropFirst()) {
            #expect(to.time > from.time, "\(from.name) to \(to.name)")
            if from.position == to.position {
                #expect(from.name == to.name, "a hold must stay at one station")
            }
        }
    }

    @Test func movingLegsRunAtTrainSpeed() {
        let movingLegs = route.legs.filter { $0.from != $0.to }

        #expect(movingLegs.count == 13)
        for leg in movingLegs {
            let metres = leg.to.sample(accuracy: 0, at: leg.end).distance(to: leg.from.sample(accuracy: 0, at: leg.start))
            let speed = metres / leg.end.timeIntervalSince(leg.start)
            #expect((8...25).contains(speed), "\(Int(metres)) m at \(speed) m/s")
        }
    }

    private static func date(_ text: String) -> Date? {
        ISO8601DateFormatter().date(from: text)
    }
}
