import ArrivalKit
import Foundation

struct Waypoint: Equatable {
    static let earthRadius = 6_371_000.0

    var latitude: Double
    var longitude: Double

    func moved(northMetres: Double = 0, eastMetres: Double = 0) -> Waypoint {
        Waypoint(
            latitude: latitude + Self.degrees(northMetres),
            longitude: longitude + Self.degrees(eastMetres) / cos(latitude * .pi / 180)
        )
    }

    func interpolated(to other: Waypoint, fraction: Double) -> Waypoint {
        Waypoint(
            latitude: latitude + (other.latitude - latitude) * fraction,
            longitude: longitude + (other.longitude - longitude) * fraction
        )
    }

    func sample(accuracy: Double, at date: Date) -> LocationSample {
        LocationSample(latitude: latitude, longitude: longitude, horizontalAccuracy: accuracy, timestamp: date)
    }

    func destination(named name: String = "Test stop") -> Destination {
        Destination(name: name, latitude: latitude, longitude: longitude)
    }

    private static func degrees(_ metres: Double) -> Double {
        metres / earthRadius * 180 / .pi
    }
}

struct RouteLeg: Equatable {
    var from: Waypoint
    var to: Waypoint
    var start: Date
    var end: Date
    var isUnderground: Bool

    func position(at date: Date) -> Waypoint {
        let duration = end.timeIntervalSince(start)
        guard duration > 0 else { return to }
        let fraction = min(max(date.timeIntervalSince(start) / duration, 0), 1)
        return from.interpolated(to: to, fraction: fraction)
    }
}

struct RouteBuilder {
    private(set) var legs: [RouteLeg] = []
    private(set) var time: Date
    private(set) var position: Waypoint

    init(from start: Waypoint, at time: Date = FixBuilder.startDate) {
        self.position = start
        self.time = time
    }

    mutating func wait(_ seconds: TimeInterval, underground: Bool = false) {
        travel(to: position, seconds: seconds, underground: underground)
    }

    mutating func travel(eastward metres: Double, speed: Double, underground: Bool = false) {
        travel(to: position.moved(eastMetres: metres), seconds: metres / speed, underground: underground)
    }

    mutating func travel(to waypoint: Waypoint, seconds: TimeInterval, underground: Bool = false) {
        let end = time.addingTimeInterval(seconds)
        legs.append(RouteLeg(from: position, to: waypoint, start: time, end: end, isUnderground: underground))
        position = waypoint
        time = end
    }
}
