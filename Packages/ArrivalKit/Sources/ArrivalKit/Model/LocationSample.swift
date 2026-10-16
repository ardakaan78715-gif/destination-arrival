import CoreLocation
import Foundation

public struct LocationSample: Sendable, Hashable {
    public var latitude: Double
    public var longitude: Double
    public var horizontalAccuracy: Double
    public var timestamp: Date

    public init(latitude: Double, longitude: Double, horizontalAccuracy: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }

    public init(_ location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracy: location.horizontalAccuracy,
            timestamp: location.timestamp
        )
    }

    public func distance(to destination: Destination) -> Double {
        location.distance(from: destination.location)
    }

    public func distance(to other: LocationSample) -> Double {
        location.distance(from: other.location)
    }

    public func closestPossibleDistance(to destination: Destination) -> Double {
        max(0, distance(to: destination) - horizontalAccuracy)
    }

    private var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
