import Foundation

public enum JourneyEffect: Sendable, Equatable {
    case startLocationUpdates(TrackingPrecision)
    case changePrecision(TrackingPrecision)
    case stopLocationUpdates
    case scheduleBackupAlarm(Date)
    case cancelBackupAlarm
    case ringAlarm(AlarmReason)
    case silenceAlarm
}
