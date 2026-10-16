import Foundation

public enum JourneyEvent: Sendable, Equatable {
    case started(Date)
    case locationReceived(LocationSample)
    case alarmStopped
    case cancelled
}
