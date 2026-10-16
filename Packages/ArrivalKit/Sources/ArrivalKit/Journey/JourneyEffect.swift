public enum JourneyEffect: Sendable, Equatable {
    case startLocationUpdates(TrackingPrecision)
    case changePrecision(TrackingPrecision)
    case stopLocationUpdates
    case ringAlarm(AlarmReason)
    case silenceAlarm
}
