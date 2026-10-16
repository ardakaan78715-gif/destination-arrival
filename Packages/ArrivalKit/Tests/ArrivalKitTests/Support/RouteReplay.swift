import ArrivalKit
import Foundation

struct ReplayOutcome {
    var ringTime: Date?
    var reason: AlarmReason?
    var arrival: Date

    var secondsEarly: TimeInterval? {
        ringTime.map { arrival.timeIntervalSince($0) }
    }
}

enum RouteReplay {
    static let tickInterval: TimeInterval = 10
    static let ticksAfterArrival: TimeInterval = 600

    private struct TimedEvent {
        var date: Date
        var event: JourneyEvent

        var sortKey: (Date, Int) {
            if case .clockTicked = event {
                return (date, 1)
            }
            return (date, 0)
        }
    }

    static func run(
        _ legs: [RouteLeg],
        to destination: Destination,
        settings: AlarmSettings = AlarmSettings(),
        extraFixes: [LocationSample] = [],
        fixInterval: TimeInterval = 1,
        accuracy: Double = 10,
        jitter: Double = 8,
        seed: UInt64 = 1
    ) -> ReplayOutcome {
        precondition(!legs.isEmpty, "A replay needs at least one leg")
        let start = legs[0].start
        let arrival = legs[legs.count - 1].end
        let horizon = arrival.addingTimeInterval(ticksAfterArrival)
        var generator = SeededGenerator(seed: seed)

        let fixes = times(from: start, through: horizon, every: fixInterval).compactMap { date -> LocationSample? in
            let leg = legs.first { date <= $0.end } ?? legs[legs.count - 1]
            guard !leg.isUnderground else { return nil }
            let shifted = leg.position(at: date).moved(
                northMetres: .random(in: -jitter...jitter, using: &generator),
                eastMetres: .random(in: -jitter...jitter, using: &generator)
            )
            return shifted.sample(accuracy: accuracy, at: date)
        }
        let fixEvents = (fixes + extraFixes).map {
            TimedEvent(date: $0.timestamp, event: .locationReceived($0))
        }
        let tickEvents = times(from: start, through: horizon, every: tickInterval).map {
            TimedEvent(date: $0, event: .clockTicked($0))
        }

        var journey = Journey(destination: destination, settings: settings)
        _ = journey.handle(.started(start))
        for timed in (fixEvents + tickEvents).sorted(by: { $0.sortKey < $1.sortKey }) {
            _ = journey.handle(timed.event)
            if case .ringing(let reason) = journey.phase {
                return ReplayOutcome(ringTime: timed.date, reason: reason, arrival: arrival)
            }
        }
        return ReplayOutcome(ringTime: nil, reason: nil, arrival: arrival)
    }

    private static func times(from start: Date, through end: Date, every interval: TimeInterval) -> [Date] {
        let count = Int(end.timeIntervalSince(start) / interval)
        return (0...count).map { start.addingTimeInterval(Double($0) * interval) }
    }
}
