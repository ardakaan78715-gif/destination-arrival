import Foundation

public enum FixVerdict: Sendable, Equatable {
    case accepted
    case invalidAccuracy
    case tooInaccurate
    case stale
    case outOfOrder
    case implausibleJump
}

public struct FixFilter: Sendable, Equatable {
    public let journeyStart: Date
    public let tuning: ArrivalTuning
    public private(set) var lastAccepted: LocationSample?

    public init(journeyStart: Date, tuning: ArrivalTuning = .standard) {
        self.journeyStart = journeyStart
        self.tuning = tuning
    }

    public mutating func accept(_ fix: LocationSample) -> FixVerdict {
        let verdict = verdict(for: fix)
        if verdict == .accepted {
            lastAccepted = fix
        }
        return verdict
    }

    private func verdict(for fix: LocationSample) -> FixVerdict {
        if !fix.horizontalAccuracy.isFinite || fix.horizontalAccuracy < 0 {
            return .invalidAccuracy
        }
        if fix.horizontalAccuracy > tuning.maximumAccuracy {
            return .tooInaccurate
        }
        if fix.timestamp < journeyStart.addingTimeInterval(-tuning.staleFixAllowance) {
            return .stale
        }
        guard let lastAccepted else {
            return .accepted
        }
        let elapsed = fix.timestamp.timeIntervalSince(lastAccepted.timestamp)
        if elapsed <= 0 {
            return .outOfOrder
        }
        if fix.distance(to: lastAccepted) / elapsed > tuning.maximumPlausibleSpeed {
            return .implausibleJump
        }
        return .accepted
    }
}
