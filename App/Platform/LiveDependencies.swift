extension AppDependencies {
    @MainActor
    static func live() -> AppDependencies {
        AppDependencies(
            location: DeviceLocationService(),
            alarms: LiveAlarmService(sound: AlarmSoundPlayer()),
            search: LocalPlaceSearch()
        )
    }
}
