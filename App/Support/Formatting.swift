import ArrivalKit
import Foundation

enum Formatting {
    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(1, (seconds / 60).rounded())
        return Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    static func leadTime(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.minutes], width: .wide))
    }

    static func distance(_ metres: Double) -> String {
        Measurement(value: metres, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    static func alarmTitle(for destination: Destination) -> String {
        "Nearly at \(destination.name)"
    }

    static func alarmReason(_ reason: AlarmReason, settings: AlarmSettings) -> String {
        switch reason {
        case .withinLeadTime:
            "About \(leadTime(settings.leadTime)) to go."
        case .insideRadius:
            "You're within \(distance(settings.radius))."
        }
    }
}
