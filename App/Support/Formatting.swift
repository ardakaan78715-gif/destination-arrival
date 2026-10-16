import ArrivalKit
import Foundation

enum Formatting {
    static let backupReminder = "Your backup alarm. Check where you are."

    private typealias DistanceWidth = Measurement<UnitLength>.FormatStyle.UnitWidth

    private static let metresPerYard = 0.9144
    private static let yardsPerMile = 1_760.0

    static func duration(_ seconds: TimeInterval) -> String {
        wholeMinutes(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    static func spokenDuration(_ seconds: TimeInterval) -> String {
        wholeMinutes(seconds).formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }

    static func leadTime(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.minutes], width: .wide))
    }

    static func distance(_ metres: Double, unit: DistanceUnit) -> String {
        distance(metres, unit: unit, width: .abbreviated)
    }

    static func spokenDistance(_ metres: Double, unit: DistanceUnit) -> String {
        distance(metres, unit: unit, width: .wide)
    }

    static func alarmTitle(for destination: Destination) -> String {
        "Nearly at \(destination.name)"
    }

    static func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func locationLost(backupAlarm: Date?) -> String {
        guard let backupAlarm else {
            return "Location access was turned off. Turn it back on in Settings so the alarm knows where you are."
        }
        return "Location access was turned off. Your backup alarm at \(clockTime(backupAlarm)) is still set."
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

    static func spokenSummary(
        estimate: ArrivalEstimate,
        at date: Date,
        destination: Destination,
        unit: DistanceUnit
    ) -> String {
        let distance = spokenDistance(estimate.distanceRemaining(at: date), unit: unit)
        guard estimate.isArmed(at: date) else {
            return "\(destination.name), \(distance) away. Alarm \(leadTime(estimate.settings.leadTime)) before arrival."
        }
        let timeLeft = spokenDuration(estimate.timeRemaining(at: date))
        let away = estimate.isSignalLost(at: date) ? "about \(distance) away" : "\(distance) away"
        return "About \(timeLeft) to \(destination.name), \(away). Alarm at about \(clockTime(estimate.alarmDate))."
    }

    static func signalStatus(_ status: SignalStatus, at date: Date) -> String {
        switch status {
        case .live:
            "Live GPS"
        case .stopped:
            "Stopped"
        case .waitingToMove:
            "Waiting to move"
        case .estimating(let since):
            "No signal for \(duration(date.timeIntervalSince(since))) · estimating"
        }
    }

    static func spokenSignalStatus(_ status: SignalStatus, at date: Date) -> String {
        switch status {
        case .estimating(let since):
            "No signal for \(spokenDuration(date.timeIntervalSince(since))), estimating"
        case .live, .stopped, .waitingToMove:
            signalStatus(status, at: date)
        }
    }

    private static func wholeMinutes(_ seconds: TimeInterval) -> Duration {
        Duration.seconds(max(1, (seconds / 60).rounded()) * 60)
    }

    private static func distance(_ metres: Double, unit: DistanceUnit, width: DistanceWidth) -> String {
        usesImperialUnits(unit) ? imperialDistance(metres, width: width) : metricDistance(metres, width: width)
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

    private static func metricDistance(_ metres: Double, width: DistanceWidth) -> String {
        let roundedMetres = roundedToTen(metres)
        if roundedMetres < 1_000 {
            return measurement(roundedMetres, .meters, fractionDigits: 0, width: width)
        }
        return measurement(metres / 1_000, .kilometers, fractionDigits: 1, width: width)
    }

    private static func imperialDistance(_ metres: Double, width: DistanceWidth) -> String {
        let yards = metres / metresPerYard
        let roundedYards = roundedToTen(yards)
        if roundedYards < yardsPerMile / 4 {
            return measurement(roundedYards, .yards, fractionDigits: 0, width: width)
        }
        return measurement(yards / yardsPerMile, .miles, fractionDigits: 1, width: width)
    }

    private static func roundedToTen(_ value: Double) -> Double {
        (value / 10).rounded() * 10
    }

    private static func measurement(
        _ value: Double,
        _ unit: UnitLength,
        fractionDigits: Int,
        width: DistanceWidth
    ) -> String {
        Measurement(value: value, unit: unit).formatted(
            .measurement(
                width: width,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(fractionDigits))
            )
        )
    }

    private static func lastFixTime(of journey: Journey) -> String {
        journey.estimate.map { clockTime($0.anchor.timestamp) } ?? "you set off"
    }
}
