import SwiftUI

@main
struct DestinationArrivalApp: App {
    @State private var journeyModel: JourneyModel
    @State private var searchModel: PlaceSearchModel

    init() {
        let dependencies = AppDependencies.live()
        _journeyModel = State(initialValue: JourneyModel(location: dependencies.location, alarms: dependencies.alarms))
        _searchModel = State(initialValue: PlaceSearchModel(places: dependencies.search))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(journeyModel)
                .environment(searchModel)
        }
    }
}
