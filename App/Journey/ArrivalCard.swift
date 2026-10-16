import ArrivalKit
import SwiftUI

struct ArrivalCard: View {
    let journey: Journey
    let unit: DistanceUnit
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(headline)
                .font(.title2.bold())
            Text(distanceLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(alarmLine)
                .font(.subheadline)
            if let estimate = journey.estimate {
                StatusChip(status: estimate.signalStatus(at: now), now: now)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenSummary)
        .accessibilityValue(spokenStatus)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var headline: String {
        guard let estimate = journey.estimate, estimate.isArmed(at: now) else {
            return journey.destination.name
        }
        return "About \(Formatting.duration(estimate.timeRemaining(at: now))) to \(journey.destination.name)"
    }

    private var distanceLine: String {
        guard let estimate = journey.estimate else {
            return "Finding your location…"
        }
        let distance = Formatting.distance(estimate.distanceRemaining(at: now), unit: unit)
        return estimate.isSignalLost(at: now) ? "About \(distance) away" : "\(distance) away"
    }

    private var alarmLine: String {
        guard let estimate = journey.estimate, estimate.isArmed(at: now) else {
            return "Alarm \(Formatting.leadTime(journey.settings.leadTime)) before arrival"
        }
        return "Alarm at about \(Formatting.clockTime(estimate.alarmDate))"
    }

    private var spokenSummary: String {
        guard let estimate = journey.estimate else {
            return "\(journey.destination.name). Finding your location. \(alarmLine)."
        }
        return Formatting.spokenSummary(estimate: estimate, at: now, destination: journey.destination, unit: unit)
    }

    private var spokenStatus: String {
        guard let estimate = journey.estimate else {
            return ""
        }
        return Formatting.spokenSignalStatus(estimate.signalStatus(at: now), at: now)
    }
}
