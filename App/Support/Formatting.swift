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

    static func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func alarmReason(_ reason: AlarmReason, for journey: Journey) -> String {
        switch reason {
        case .withinLeadTime:
            "About \(leadTime(journey.settings.leadTime)) to go."
        case .insideRadius:
            "You're within \(distance(journey.settings.radius))."
        case .projectedDuringSignalLoss:
            "No signal since \(lastFixTime(of: journey)). You're probably close, so we woke you early rather than late."
        }
    }

    private static func lastFixTime(of journey: Journey) -> String {
        journey.estimate.map { clockTime($0.anchor.timestamp) } ?? "you set off"
    }
}
