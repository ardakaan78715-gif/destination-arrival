import ArrivalKit
import MapKit

extension ServiceArea {
    var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: north - south, longitudeDelta: east - west)
        )
    }
}
