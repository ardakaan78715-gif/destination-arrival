import ArrivalKit
import Foundation

enum Formatting {
    static let backupReminder = "Your backup alarm. Check where you are."

    private static let metresPerYard = 0.9144
    private static let yardsPerMile = 1_760.0

    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = max(1, (seconds / 60).rounded())
        return Duration.seconds(minutes * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    static func leadTime(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.minutes], width: .wide))
    }

    static func distance(_ metres: Double, unit: DistanceUnit) -> String {
        usesImperialUnits(unit) ? imperialDistance(metres) : metricDistance(metres)
    }

    static func alarmTitle(for destination: Destination) -> String {
        "Nearly at \(destination.name)"
    }

    static func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func alarmReason(_ reason: AlarmReason, for journey: Journey, unit: DistanceUnit) -> String {
        switch reason {
        case .withinLeadTime:
            "About \(leadTime(journey.settings.leadTime)) to go."
        case .insideRadius:
            "You're within \(distance(journey.settings.radius, unit: unit))."
        case .projectedDuringSignalLoss:
            "No signal since \(lastFixTime(of: journey)). You're probably close, so we woke you early rather than late."
        case .scheduledBackup:
            backupReminder
        }
    }

    private static func usesImperialUnits(_ unit: DistanceUnit) -> Bool {
        switch unit {
        case .system:
            Locale.current.measurementSystem != .metric
        case .metric:
            false
        case .imperial:
            true
        }
    }

    private static func metricDistance(_ metres: Double) -> String {
        let roundedMetres = roundedToTen(metres)
        if roundedMetres < 1_000 {
            return measurement(roundedMetres, .meters, fractionDigits: 0)
        }
        return measurement(metres / 1_000, .kilometers, fractionDigits: 1)
    }

    private static func imperialDistance(_ metres: Double) -> String {
        let yards = metres / metresPerYard
        let roundedYards = roundedToTen(yards)
        if roundedYards < yardsPerMile / 4 {
            return measurement(roundedYards, .yards, fractionDigits: 0)
        }
        return measurement(yards / yardsPerMile, .miles, fractionDigits: 1)
    }

    private static func roundedToTen(_ value: Double) -> Double {
        (value / 10).rounded() * 10
    }

    private static func measurement(_ value: Double, _ unit: UnitLength, fractionDigits: Int) -> String {
        Measurement(value: value, unit: unit).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(fractionDigits))
            )
        )
    }

    private static func lastFixTime(of journey: Journey) -> String {
        journey.estimate.map { clockTime($0.anchor.timestamp) } ?? "you set off"
    }
}
