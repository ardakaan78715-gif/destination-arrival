import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                testSection
                tipsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var unitsSection: some View {
        @Bindable var settingsStore = settingsStore
        return Section {
            Picker("Distance units", selection: $settingsStore.distanceUnit) {
                ForEach(DistanceUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
        }
    }

    private var testSection: some View {
        Section {
            Button {
                journeyModel.playTestAlarm()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Test the alarm")
                        Text("Plays at your current media volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "speaker.wave.3.fill")
                }
            }
        }
    }

    private var tipsSection: some View {
        Section("Making sure you hear it") {
            Label("Turn the volume up. The alarm follows media volume, not the ringer.", systemImage: "speaker.wave.2.fill")
            Label("Allow notifications, so the alarm also shows on the lock screen.", systemImage: "bell.badge.fill")
            Label("Allow Destination Arrival in any Focus you travel with, such as Sleep.", systemImage: "moon.fill")
            Label("Leave the app open in the background. Swiping it away stops tracking.", systemImage: "iphone")
        }
        .font(.subheadline)
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: version)
            Text("Released under the MIT licence")
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
}
