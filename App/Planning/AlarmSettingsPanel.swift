import ArrivalKit
import SwiftUI

struct AlarmSettingsPanel: View {
    @Environment(JourneyModel.self) private var journeyModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let draft = journeyModel.draft {
                destinationHeader(draft)
                leadTimePicker
                startButton
            } else {
                Text("Search or tap the map to choose where you're going")
                    .font(.headline)
            }
            if let notice = journeyModel.notice {
                Label(notice.message, systemImage: "exclamationmark.triangle.fill")
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
