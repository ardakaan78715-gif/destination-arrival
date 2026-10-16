import ArrivalKit
import Foundation

@MainActor
protocol AlarmService: AnyObject {
    var onStopRequested: (@MainActor () -> Void)? { get set }
    var onBackupDelivered: (@MainActor () -> Void)? { get set }
    func requestPermission() async
    func ring(for journey: Journey, reason: AlarmReason, unit: DistanceUnit)
    func silence()
    func scheduleBackup(at date: Date, for journey: Journey)
    func cancelBackup()
    func playTest()
}
