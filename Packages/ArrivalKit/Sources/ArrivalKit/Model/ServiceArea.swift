import Foundation

public struct ServiceArea: Sendable, Hashable {
    public var name: String
    public var south: Double
    public var west: Double
    public var north: Double
    public var east: Double

    public init(name: String, south: Double, west: Double, north: Double, east: Double) {
        self.name = name
        self.south = south
        self.west = west
        self.north = north
        self.east = east
    }

    public static let london = ServiceArea(name: "London", south: 51.28, west: -0.52, north: 51.70, east: 0.34)

    public func contains(latitude: Double, longitude: Double) -> Bool {
        (south...north).contains(latitude) && (west...east).contains(longitude)
    }

    public func contains(_ destination: Destination) -> Bool {
        contains(latitude: destination.latitude, longitude: destination.longitude)
    }

    public var centerLatitude: Double {
        (south + north) / 2
    }

    public var centerLongitude: Double {
        (west + east) / 2
    }
}
