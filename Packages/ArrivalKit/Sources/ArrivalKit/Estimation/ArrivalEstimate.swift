import Foundation

public enum SpeedSource: Sendable, Equatable {
    case measured
}

public struct ArrivalEstimate: Sendable, Equatable {
    public let anchor: LocationSample
    public let distance: Double
    public let speed: Double?
    public let isMoving: Bool
    public let settings: AlarmSettings

    public init(
        anchor: LocationSample,
        destination: Destination,
        cruiseSpeed: Double?,
        isMoving: Bool,
        settings: AlarmSettings
    ) {
        self.anchor = anchor
        self.distance = max(0, anchor.distance(to: destination) - anchor.horizontalAccuracy)
        self.speed = cruiseSpeed
        self.isMoving = isMoving
        self.settings = settings
    }

    public var speedSource: SpeedSource? {
        speed == nil ? nil : .measured
    }

    public var timeRemaining: TimeInterval? {
        speed.map { distance / $0 }
    }

    public var alarmDistance: Double {
        max((speed ?? 0) * settings.leadTime, settings.radius)
    }

    public var alarmReason: AlarmReason? {
        if distance <= settings.radius {
            return .insideRadius
        }
        if speedSource == .measured, distance <= alarmDistance {
            return .withinLeadTime
        }
        return nil
    }
}
