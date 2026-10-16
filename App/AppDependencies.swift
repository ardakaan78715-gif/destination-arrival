import Foundation

struct AppDependencies {
    var location: any LocationService
    var alarms: any AlarmService
    var search: any PlaceSearching
    var readiness: any ReadinessProbing
    var settingsURL: URL?
    var tunnel: TunnelSimulator?
}
