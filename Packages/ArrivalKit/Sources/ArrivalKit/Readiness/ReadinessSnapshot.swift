import Foundation

public enum LocationAccess: Sendable, Hashable {
    case notDetermined
    case denied
    case restricted
    case whenInUse
    case always

    var isGranted: Bool {
        self == .whenInUse || self == .always
    }
}

public enum NotificationAccess: Sendable, Hashable {
    case notDetermined
    case denied
    case allowed
}

public struct ReadinessSnapshot: Sendable, Hashable {
    public var location: LocationAccess
    public var hasPreciseLocation: Bool
    public var notifications: NotificationAccess
    public var isLowPowerModeOn: Bool
    public var isVolumeLow: Bool
    public var distanceToDestination: Double?
    public var radius: Double

    public init(
        location: LocationAccess,
        hasPreciseLocation: Bool,
        notifications: NotificationAccess,
        isLowPowerModeOn: Bool,
        isVolumeLow: Bool,
        distanceToDestination: Double?,
        radius: Double
    ) {
        self.location = location
        self.hasPreciseLocation = hasPreciseLocation
        self.notifications = notifications
        self.isLowPowerModeOn = isLowPowerModeOn
        self.isVolumeLow = isVolumeLow
        self.distanceToDestination = distanceToDestination
        self.radius = radius
    }
}
