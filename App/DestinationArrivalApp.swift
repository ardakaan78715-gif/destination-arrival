import SwiftUI

@main
struct DestinationArrivalApp: App {
    @State private var settingsStore: SettingsStore
    @State private var placeHistory: PlaceHistoryStore
    @State private var journeyModel: JourneyModel
    @State private var searchModel: PlaceSearchModel

    init() {
        let dependencies = AppDependencies.live()
        let settingsStore = SettingsStore()
        let placeHistory = PlaceHistoryStore()
        _settingsStore = State(initialValue: settingsStore)
        _placeHistory = State(initialValue: placeHistory)
        _journeyModel = State(initialValue: JourneyModel(
            dependencies: dependencies,
            settingsStore: settingsStore,
            placeHistory: placeHistory
        ))
        _searchModel = State(initialValue: PlaceSearchModel(places: dependencies.search))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settingsStore)
                .environment(placeHistory)
                .environment(journeyModel)
                .environment(searchModel)
        }
    }
}
