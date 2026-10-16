public enum JourneyEffect: Sendable, Equatable {
    case startLocationUpdates
    case stopLocationUpdates
    case ringAlarm(AlarmReason)
    case silenceAlarm
}
