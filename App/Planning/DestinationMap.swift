import ArrivalKit
import MapKit
import SwiftUI

struct DestinationMap: View {
    @Environment(JourneyModel.self) private var journeyModel
    @State private var position = MapCameraPosition.userLocation(fallback: .region(ServiceArea.london.region))

    var body: some View {
        MapReader { proxy in
            Map(position: $position, bounds: londonBounds) {
                UserAnnotation()
                if let draft = journeyModel.draft {
                    DestinationMarker(destination: draft, radius: journeyModel.settings.radius)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .accessibilityLabel("Map of London")
            .accessibilityHint("Tap to drop a pin, or use Search")
            .onTapGesture { point in
                if let coordinate = proxy.convert(point, from: .local) {
                    journeyModel.dropPin(at: coordinate)
                }
            }
        }
        .onChange(of: journeyModel.draft) { _, draft in
            if let draft {
                focus(on: draft)
            }
        }
    }

    private var londonBounds: MapCameraBounds {
        MapCameraBounds(
            centerCoordinateBounds: ServiceArea.london.region,
            minimumDistance: 300,
            maximumDistance: 80_000
        )
    }

    private func focus(on destination: Destination) {
        let span = journeyModel.settings.radius * 4
        withAnimation {
            position = .region(
                MKCoordinateRegion(center: destination.coordinate, latitudinalMeters: span, longitudinalMeters: span)
            )
        }
    }
}

struct DestinationMarker: MapContent {
    let destination: Destination
    let radius: Double

    var body: some MapContent {
        Marker(destination.name, coordinate: destination.coordinate)
            .tint(.orange)
        MapCircle(center: destination.coordinate, radius: radius)
            .foregroundStyle(.orange.opacity(0.15))
            .stroke(.orange, lineWidth: 2)
    }
}
