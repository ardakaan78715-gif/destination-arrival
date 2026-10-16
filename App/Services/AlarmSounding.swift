import Foundation

@MainActor
protocol AlarmSounding: AnyObject {
    var isVolumeLow: Bool { get }
    func start()
    func stop()
    func playSample(seconds: TimeInterval)
}
