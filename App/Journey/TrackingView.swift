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
                journeyCard(journey)
            }
        }
    }

    private func journeyCard(_ journey: Journey) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(journey.destination.name)
                .font(.headline)
            Text(arrivalLine(for: journey.estimate))
                .font(.title2.bold())
            Text(distanceLine(for: journey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

    private func arrivalLine(for estimate: ArrivalEstimate?) -> String {
        guard let timeRemaining = estimate?.timeRemaining else {
            return "Measuring your speed…"
        }
        return "About \(Formatting.duration(timeRemaining)) to go"
    }

    private func distanceLine(for journey: Journey) -> String {
        let alarm = "Alarm \(Formatting.leadTime(journey.settings.leadTime)) before arrival"
        guard let estimate = journey.estimate else {
            return "Finding your location… · \(alarm)"
        }
        return "\(Formatting.distance(estimate.distance)) away · \(alarm)"
    }
}
