import Foundation

public enum SignalStatus: Sendable, Equatable {
    case live
    case stopped
    case waitingToMove
    case estimating(since: Date)
}
