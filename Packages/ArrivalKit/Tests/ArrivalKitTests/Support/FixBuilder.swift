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
    var interval: TimeInterval = 1
    var count = 60
    var accuracy = 10.0

    func samples() -> [LocationSample] {
        (0..<count).map { index in
            let elapsed = Double(index) * interval
            return sample(afterMetres: speed * elapsed, elapsed: elapsed)
        }
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
        let degrees = metres / Self.earthRadius * 180 / .pi
        switch bearing {
        case .north:
            return (latitude + degrees, longitude)
        case .east:
            return (latitude, longitude + degrees / cos(latitude * .pi / 180))
        }
    }
}
