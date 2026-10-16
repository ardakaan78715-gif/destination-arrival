import Foundation

public enum JourneyEvent: Sendable, Equatable {
    case started(Date)
    case locationReceived(LocationSample)
    case clockTicked(Date)
    case alarmStopped
    case cancelled
}
