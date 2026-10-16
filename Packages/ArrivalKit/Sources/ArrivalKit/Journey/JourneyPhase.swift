public enum JourneyPhase: Sendable, Equatable {
    case ready
    case tracking
    case ringing(AlarmReason)
    case finished
}

public enum AlarmReason: Sendable, Equatable {
    case withinLeadTime
    case insideRadius
}
