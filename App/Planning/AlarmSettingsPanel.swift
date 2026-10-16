import ArrivalKit
import SwiftUI

struct AlarmSettingsPanel: View {
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(PlaceHistoryStore.self) private var placeHistory

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let draft = journeyModel.draft {
                destinationHeader(draft)
                leadTimePicker
                radiusSlider
                startButton
            } else {
                Text("Search or tap the map to choose where you're going")
                    .font(.headline)
                if !placeHistory.history.isEmpty {
                    SavedPlacesBar()
                }
            }
            if journeyModel.notice == .outsideLondon {
                Label("Pick somewhere in London for now.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func destinationHeader(_ destination: Destination) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(.title3.bold())
                if let detail = destination.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            favouriteButton(for: destination)
        }
    }

    private func favouriteButton(for destination: Destination) -> some View {
        let isFavourite = placeHistory.history.isFavourite(destination)
        return Button(
            isFavourite ? "Remove from favourites" : "Add to favourites",
            systemImage: isFavourite ? "star.fill" : "star"
        ) {
            placeHistory.update { $0.toggleFavourite(destination) }
        }
        .labelStyle(.iconOnly)
        .font(.title2)
        .tint(.orange)
    }

    private var leadTimePicker: some View {
        @Bindable var journeyModel = journeyModel
        return VStack(alignment: .leading, spacing: 8) {
            Text("Wake me \(Formatting.leadTime(journeyModel.settings.leadTime)) before I arrive")
                .font(.subheadline)
            Picker("Wake me before arrival", selection: $journeyModel.settings.leadTime) {
                ForEach(AlarmSettings.leadTimeChoices, id: \.self) { choice in
                    Text("\(Int(choice / 60)) min").tag(choice)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var radiusSlider: some View {
        @Bindable var journeyModel = journeyModel
        let radius = Formatting.distance(journeyModel.settings.radius, unit: journeyModel.distanceUnit)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Or when within \(radius)")
                .font(.subheadline)
            Slider(
                value: $journeyModel.settings.radius,
                in: AlarmSettings.radiusRange,
                step: AlarmSettings.radiusStep
            ) {
                Text("Wake radius")
            }
        }
    }

    private var startButton: some View {
        Button {
            Task { await journeyModel.start() }
        } label: {
            Text("Start journey")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(journeyModel.isStarting)
    }
}
