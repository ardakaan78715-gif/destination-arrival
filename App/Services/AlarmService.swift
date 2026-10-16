import ArrivalKit

@MainActor
protocol AlarmService: AnyObject {
    func requestPermission() async -> Bool
    func ring(for journey: Journey, reason: AlarmReason)
    func silence()
}
