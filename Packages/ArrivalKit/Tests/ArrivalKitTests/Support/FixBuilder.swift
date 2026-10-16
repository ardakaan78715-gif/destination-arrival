import ArrivalKit
import Foundation

struct FixBuilder {
    enum Bearing {
        case east
        case north
    }

    static let startDate = Date(timeIntervalSinceReferenceDate: 800_000_000)
    static let earthRadius = 6_371_000.0

    var latitude = 51.5
    var longitude = -0.2
    var start = FixBuilder.startDate
    var bearing = Bearing.east
    var speed = 15.0
    var deceleration = 0.0
    var interval: TimeInterval = 1
    var count = 60
    var accuracy = 10.0
    var jitter = 0.0
    var seed: UInt64 = 0

    func samples() -> [LocationSample] {
        var generator = SeededGenerator(seed: seed)
        return (0..<count).map { index in
            let elapsed = Double(index) * interval
            let fix = sample(afterMetres: travelled(after: elapsed), elapsed: elapsed)
            return Self.shifted(
                fix,
                northMetres: .random(in: -jitter...jitter, using: &generator),
                eastMetres: .random(in: -jitter...jitter, using: &generator)
            )
        }
    }

    func jittered(maxMetres: Double, seed: UInt64) -> FixBuilder {
        var builder = self
        builder.jitter = maxMetres
        builder.seed = seed
        return builder
    }

    func continued(speed: Double, count: Int) -> FixBuilder {
        let elapsed = Double(self.count) * interval
        let end = coordinate(afterMetres: travelled(after: elapsed))
        var builder = self
        builder.latitude = end.latitude
        builder.longitude = end.longitude
        builder.start = start.addingTimeInterval(elapsed)
        builder.speed = speed
        builder.deceleration = 0
        builder.count = count
        return builder
    }

    func braking(at deceleration: Double, count: Int) -> FixBuilder {
        var builder = continued(speed: speed, count: count)
        builder.deceleration = deceleration
        return builder
    }

    func travelled(after elapsed: TimeInterval) -> Double {
        guard deceleration > 0 else { return speed * elapsed }
        let moving = min(elapsed, speed / deceleration)
        return speed * moving - deceleration * moving * moving / 2
    }

    func sample(afterMetres metres: Double, elapsed: TimeInterval = 0) -> LocationSample {
        let point = coordinate(afterMetres: metres)
        return LocationSample(
            latitude: point.latitude,
            longitude: point.longitude,
            horizontalAccuracy: accuracy,
            timestamp: start.addingTimeInterval(elapsed)
        )
    }

    func destination(afterMetres metres: Double) -> Destination {
        let point = coordinate(afterMetres: metres)
        return Destination(name: "Test stop", latitude: point.latitude, longitude: point.longitude)
    }

    func coordinate(afterMetres metres: Double) -> (latitude: Double, longitude: Double) {
        switch bearing {
        case .north:
            return (latitude + Self.degrees(metres), longitude)
        case .east:
            return (latitude, longitude + Self.degrees(metres) / cos(latitude * .pi / 180))
        }
    }

    private static func shifted(_ fix: LocationSample, northMetres: Double, eastMetres: Double) -> LocationSample {
        var shifted = fix
        shifted.latitude += degrees(northMetres)
        shifted.longitude += degrees(eastMetres) / cos(fix.latitude * .pi / 180)
        return shifted
    }

    private static func degrees(_ metres: Double) -> Double {
        metres / earthRadius * 180 / .pi
    }
}
