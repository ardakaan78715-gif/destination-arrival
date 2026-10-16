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
            ArrivalCard(journey: journey)
            if let notice = journeyModel.notice {
                Label(notice.message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
