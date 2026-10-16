import UIKit

extension AppDependencies {
    @MainActor
    static func live() -> AppDependencies {
        let deviceLocation = DeviceLocationService()
        let sound = AlarmSoundPlayer()
        var dependencies = AppDependencies(
            location: deviceLocation,
            alarms: LiveAlarmService(sound: sound),
            search: LocalPlaceSearch(),
            readiness: DeviceReadinessProbe(location: deviceLocation, sound: sound),
            settingsURL: URL(string: UIApplication.openSettingsURLString),
            tunnel: nil
        )
        #if DEBUG
        let tunnel = TunnelSimulator(wrapping: deviceLocation)
        dependencies.location = tunnel
        dependencies.tunnel = tunnel
        #endif
        return dependencies
    }
}
