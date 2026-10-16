import CoreLocation
import Foundation

public struct Destination: Sendable, Hashable, Codable, Identifiable {
    public var name: String
    public var detail: String?
    public var latitude: Double
    public var longitude: Double

    public init(name: String, detail: String? = nil, latitude: Double, longitude: Double) {
        self.name = name
        self.detail = detail
        self.latitude = latitude
        self.longitude = longitude
    }

    public static func droppedPin(latitude: Double, longitude: Double) -> Destination {
        Destination(
            name: "Dropped pin",
            detail: String(format: "%.4f, %.4f", latitude, longitude),
            latitude: latitude,
            longitude: longitude
        )
    }

    public var id: String {
        "\(latitude),\(longitude)"
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
