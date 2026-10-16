import ArrivalKit
import SwiftUI

struct PlanView: View {
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(PlaceSearchModel.self) private var searchModel
    @State private var isSearchPresented = false
    @State private var isSettingsPresented = false

    var body: some View {
        @Bindable var searchModel = searchModel
        NavigationStack {
            DestinationMap()
                .safeAreaInset(edge: .bottom) {
                    AlarmSettingsPanel()
                }
                .navigationTitle("Destination Arrival")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Settings", systemImage: "gearshape") {
                            isSettingsPresented = true
                        }
                    }
                }
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView()
                }
                .searchable(text: $searchModel.query, isPresented: $isSearchPresented, prompt: "Search London")
                .searchSuggestions {
                    if searchModel.isSearching && searchModel.results.isEmpty {
                        ProgressView()
                    }
                    ForEach(searchModel.results) { suggestion in
                        Button {
                            choose(suggestion.destination)
                        } label: {
                            SearchSuggestionRow(
                                destination: suggestion.destination,
                                systemImage: suggestion.isStation ? "tram.fill" : "mappin"
                            )
                        }
                    }
                }
                .task(id: searchModel.query) {
                    await searchModel.search()
                }
        }
    }

    private func choose(_ destination: Destination) {
        journeyModel.select(destination)
        searchModel.query = ""
        isSearchPresented = false
    }
}
