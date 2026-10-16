import ArrivalKit
import SwiftUI

struct AlarmSettingsPanel: View {
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(PlaceHistoryStore.self) private var placeHistory
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var content: some View {
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
    }

    private var headerLayout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
        } else {
            AnyLayout(HStackLayout(alignment: .top))
        }
    }

    private func destinationHeader(_ destination: Destination) -> some View {
        headerLayout {
            VStack(alignment: .leading, spacing: 2) {
                Text(destination.name)
                    .font(.title3.bold())
                    .accessibilityAddTraits(.isHeader)
                if let detail = destination.detail {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        let picker = Picker("Wake me before arrival", selection: $journeyModel.settings.leadTime) {
            ForEach(AlarmSettings.leadTimeChoices, id: \.self) { choice in
                Text(leadTimeTitle(choice))
                    .accessibilityLabel(Formatting.leadTime(choice))
                    .tag(choice)
            }
        }
        .labelsHidden()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Wake me \(Formatting.leadTime(journeyModel.settings.leadTime)) before I arrive")
                .font(.subheadline)
                .accessibilityHidden(true)
            if dynamicTypeSize.isAccessibilitySize {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.segmented)
            }
        }
    }

    private func leadTimeTitle(_ choice: TimeInterval) -> String {
        dynamicTypeSize.isAccessibilitySize ? Formatting.leadTime(choice) : Formatting.duration(choice)
    }

    private var radiusSlider: some View {
        @Bindable var journeyModel = journeyModel
        let radius = journeyModel.settings.radius
        let unit = journeyModel.distanceUnit
        return VStack(alignment: .leading, spacing: 8) {
            Text("Or when within \(Formatting.distance(radius, unit: unit))")
                .font(.subheadline)
                .accessibilityHidden(true)
            Slider(
                value: $journeyModel.settings.radius,
                in: AlarmSettings.radiusRange,
                step: AlarmSettings.radiusStep
            ) {
                Text("Or wake me within")
            }
            .accessibilityValue(Formatting.spokenDistance(radius, unit: unit))
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
