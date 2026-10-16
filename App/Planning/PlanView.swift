import ArrivalKit
import SwiftUI

struct PlanView: View {
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(PlaceSearchModel.self) private var searchModel
    @Environment(PlaceHistoryStore.self) private var placeHistory
    @State private var isSearchPresented = false
    @State private var isSettingsPresented = false

    var body: some View {
        @Bindable var searchModel = searchModel
        @Bindable var journeyModel = journeyModel
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
                .sheet(item: $journeyModel.readinessCheck) { check in
                    ReadinessSheet(check: check)
                }
                .searchable(text: $searchModel.query, isPresented: $isSearchPresented, prompt: "Search London")
                .searchSuggestions {
                    if searchModel.query.isEmpty {
                        savedPlaceSuggestions
                    } else {
                        searchResultSuggestions
                    }
                }
                .task(id: searchModel.query) {
                    await searchModel.search()
                }
        }
    }

    @ViewBuilder
    private var savedPlaceSuggestions: some View {
        ForEach(placeHistory.history.favourites) { place in
            suggestionButton(for: place, kind: .favourite)
        }
        ForEach(placeHistory.history.recents) { place in
            suggestionButton(for: place, kind: .recent)
        }
    }

    @ViewBuilder
    private var searchResultSuggestions: some View {
        if searchModel.isSearching && searchModel.results.isEmpty {
            ProgressView()
                .accessibilityLabel("Searching")
        }
        ForEach(searchModel.results) { suggestion in
            suggestionButton(for: suggestion.destination, kind: suggestion.isStation ? .station : .place)
        }
    }

    private func suggestionButton(for destination: Destination, kind: PlaceKind) -> some View {
        Button {
            choose(destination)
        } label: {
            SearchSuggestionRow(destination: destination, kind: kind)
        }
    }

    private func choose(_ destination: Destination) {
        journeyModel.select(destination)
        searchModel.query = ""
        isSearchPresented = false
    }
}
