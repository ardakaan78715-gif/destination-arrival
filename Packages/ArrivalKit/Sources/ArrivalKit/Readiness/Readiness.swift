import Foundation

public enum ReadinessIssue: Sendable, Hashable, CaseIterable {
    case locationDenied
    case locationRestricted
    case alreadyThere
    case approximateLocation
    case notificationsDenied
    case lowPowerMode
    case volumeLow

    public var isBlocking: Bool {
        switch self {
        case .locationDenied, .locationRestricted, .alreadyThere:
            true
        case .approximateLocation, .notificationsDenied, .lowPowerMode, .volumeLow:
            false
        }
    }
}

public enum Readiness {
    public static func issues(for snapshot: ReadinessSnapshot) -> [ReadinessIssue] {
        let found = ReadinessIssue.allCases.filter { $0.applies(to: snapshot) }
        return found.filter(\.isBlocking) + found.filter { !$0.isBlocking }
    }

    public static func distance(
        from sample: LocationSample?,
        to destination: Destination,
        at date: Date,
        tuning: ArrivalTuning = .standard
    ) -> Double? {
        guard let sample else { return nil }
        var filter = FixFilter(journeyStart: date, tuning: tuning)
        guard filter.accept(sample) == .accepted else { return nil }
        return sample.closestPossibleDistance(to: destination)
    }
}

private extension ReadinessIssue {
    func applies(to snapshot: ReadinessSnapshot) -> Bool {
        switch self {
        case .locationDenied:
            snapshot.location == .denied
        case .locationRestricted:
            snapshot.location == .restricted
        case .alreadyThere:
            snapshot.distanceToDestination.map { $0 <= snapshot.radius } ?? false
        case .approximateLocation:
            snapshot.location.isGranted && !snapshot.hasPreciseLocation
        case .notificationsDenied:
            snapshot.notifications == .denied
        case .lowPowerMode:
            snapshot.isLowPowerModeOn
        case .volumeLow:
            snapshot.isVolumeLow
        }
    }
}
