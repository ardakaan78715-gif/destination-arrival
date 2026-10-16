import ArrivalKit
import SwiftUI

struct ArrivalCard: View {
    let journey: Journey
    let unit: DistanceUnit

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 8) {
                Text(headline(at: context.date))
                    .font(.title2.bold())
                Text(distanceLine(at: context.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(alarmLine(at: context.date))
                    .font(.subheadline)
                if let estimate = journey.estimate {
                    StatusChip(status: estimate.signalStatus(at: context.date), now: context.date)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func headline(at date: Date) -> String {
        guard let estimate = journey.estimate, estimate.isArmed(at: date) else {
            return journey.destination.name
        }
        return "About \(Formatting.duration(estimate.timeRemaining(at: date))) to \(journey.destination.name)"
    }

    private func distanceLine(at date: Date) -> String {
        guard let estimate = journey.estimate else {
            return "Finding your location…"
        }
        let distance = Formatting.distance(estimate.distanceRemaining(at: date), unit: unit)
        return estimate.isSignalLost(at: date) ? "About \(distance) away" : "\(distance) away"
    }

    private func alarmLine(at date: Date) -> String {
        guard let estimate = journey.estimate, estimate.isArmed(at: date) else {
            return "Alarm \(Formatting.leadTime(journey.settings.leadTime)) before arrival"
        }
        return "Alarm at about \(Formatting.clockTime(estimate.alarmDate))"
    }
}
