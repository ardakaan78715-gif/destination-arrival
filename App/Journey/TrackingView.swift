import ArrivalKit
import MapKit
import SwiftUI

struct TrackingView: View {
    @Environment(JourneyModel.self) private var journeyModel
    @State private var position = MapCameraPosition.automatic

    var body: some View {
        if let journey = journeyModel.journey {
            Map(position: $position) {
                UserAnnotation()
                DestinationMarker(destination: journey.destination, radius: journey.settings.radius)
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .safeAreaInset(edge: .bottom) {
                journeyPanel(journey)
            }
        }
    }

    private func journeyPanel(_ journey: Journey) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ArrivalCard(journey: journey, unit: journeyModel.distanceUnit)
            ForEach(journeyModel.notices, id: \.self) { notice in
                Label(notice.message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Text("Keep Destination Arrival open in the background. Swiping it away stops tracking.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let tunnel = journeyModel.tunnel {
                TunnelToggle(tunnel: tunnel)
            }
            Button(role: .destructive) {
                journeyModel.cancel()
            } label: {
                Text("End journey")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

private struct TunnelToggle: View {
    @Bindable var tunnel: TunnelSimulator

    var body: some View {
        Toggle("Simulate a tunnel", isOn: $tunnel.isInTunnel)
            .font(.subheadline)
    }
}
