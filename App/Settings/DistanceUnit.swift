enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
    case system
    case metric
    case imperial

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .system:
            "Device setting"
        case .metric:
            "Kilometres"
        case .imperial:
            "Miles"
        }
    }
}
