import ArrivalKit
import SwiftUI

struct ReadinessSheet: View {
    let check: JourneyModel.ReadinessCheck
    @Environment(JourneyModel.self) private var journeyModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(check.issues, id: \.self) { issue in
                        ReadinessRow(issue: issue, settingsURL: journeyModel.settingsURL)
                    }
                } footer: {
                    Text(footer)
                }
            }
            .navigationTitle(check.canStartAnyway ? "Before you set off" : "Can't start yet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(check.canStartAnyway ? "Not now" : "Close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if check.canStartAnyway {
                    startAnywayButton
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await journeyModel.start() }
            }
        }
    }

    private var footer: String {
        if check.canStartAnyway {
            return "You can still start the journey, but the alarm will be easier to miss."
        }
        return "The journey can't start until this is sorted. If you change a setting, the check runs again when you come back."
    }

    private var startAnywayButton: some View {
        Button {
            journeyModel.startAnyway()
        } label: {
            Text("Start anyway")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(journeyModel.isStarting)
        .padding()
        .background(.bar)
    }
}

private struct ReadinessRow: View {
    let issue: ReadinessIssue
    let settingsURL: URL?
    @Environment(\.openURL) private var openURL

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 6) {
                Text(issue.title)
                    .font(.headline)
                Text(issue.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let settingsURL, issue.isFixedInSettings {
                    Button("Open Settings") {
                        openURL(settingsURL)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 2)
                }
            }
        } icon: {
            Image(systemName: issue.systemImage)
                .foregroundStyle(issue.isBlocking ? Color.red : Color.orange)
        }
        .padding(.vertical, 4)
    }
}

private extension ReadinessIssue {
    var title: String {
        switch self {
        case .locationDenied:
            "Turn on location"
        case .locationRestricted:
            "Location is restricted"
        case .alreadyThere:
            "You're already there"
        case .approximateLocation:
            "Turn on Precise Location"
        case .notificationsDenied:
            "Turn on notifications"
        case .lowPowerMode:
            "Low Power Mode is on"
        case .volumeLow:
            "Turn the volume up"
        }
    }

    var explanation: String {
        switch self {
        case .locationDenied:
            "Location is off for Destination Arrival. Turn it on in Settings so the alarm knows where you are."
        case .locationRestricted:
            "Location is restricted on this iPhone, for example by Screen Time or device management, so the alarm cannot follow your journey."
        case .alreadyThere:
            "You're already within the alarm radius of this place."
        case .approximateLocation:
            "Precise Location is off. The radius alarm may ring late."
        case .notificationsDenied:
            "Notifications are off. The alarm can only sound while the app is running."
        case .lowPowerMode:
            "Low Power Mode is on. iOS may slow down location updates."
        case .volumeLow:
            "Turn your volume up. The alarm uses media volume."
        }
    }

    var systemImage: String {
        switch self {
        case .locationDenied:
            "location.slash.fill"
        case .locationRestricted:
            "hand.raised.fill"
        case .alreadyThere:
            "mappin.and.ellipse"
        case .approximateLocation:
            "location.circle"
        case .notificationsDenied:
            "bell.slash.fill"
        case .lowPowerMode:
            "battery.25"
        case .volumeLow:
            "speaker.wave.1.fill"
        }
    }

    var isFixedInSettings: Bool {
        switch self {
        case .locationDenied, .approximateLocation, .notificationsDenied:
            true
        case .locationRestricted, .alreadyThere, .lowPowerMode, .volumeLow:
            false
        }
    }
}
