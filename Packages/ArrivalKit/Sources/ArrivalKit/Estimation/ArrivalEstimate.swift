import Foundation

public struct ArrivalEstimate: Sendable, Equatable {
    public var distance: Double
    public var speed: Double?
    public var settings: AlarmSettings

    public init(distance: Double, speed: Double?, settings: AlarmSettings) {
        self.distance = distance
        self.speed = speed
        self.settings = settings
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
        if speed != nil, distance <= alarmDistance {
            return .withinLeadTime
        }
        return nil
    }
}
