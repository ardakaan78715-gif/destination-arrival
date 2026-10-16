import SwiftUI

@main
struct DestinationArrivalApp: App {
    @State private var settingsStore: SettingsStore
    @State private var journeyModel: JourneyModel
    @State private var searchModel: PlaceSearchModel

    init() {
        let dependencies = AppDependencies.live()
        let settingsStore = SettingsStore()
        _settingsStore = State(initialValue: settingsStore)
        _journeyModel = State(initialValue: JourneyModel(
            location: dependencies.location,
            alarms: dependencies.alarms,
            settingsStore: settingsStore,
            tunnel: dependencies.tunnel
        ))
        _searchModel = State(initialValue: PlaceSearchModel(places: dependencies.search))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settingsStore)
                .environment(journeyModel)
                .environment(searchModel)
        }
    }
}
