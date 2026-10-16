extension AppDependencies {
    @MainActor
    static func live() -> AppDependencies {
        var dependencies = AppDependencies(
            location: DeviceLocationService(),
            alarms: LiveAlarmService(sound: AlarmSoundPlayer()),
            search: LocalPlaceSearch(),
            tunnel: nil
        )
        #if DEBUG
        let tunnel = TunnelSimulator(wrapping: dependencies.location)
        dependencies.location = tunnel
        dependencies.tunnel = tunnel
        #endif
        return dependencies
    }
}
