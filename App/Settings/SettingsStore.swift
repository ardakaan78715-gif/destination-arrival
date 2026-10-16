import ArrivalKit
import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    var alarm: AlarmSettings {
        didSet { save(alarm, forKey: Key.alarm) }
    }

    var distanceUnit: DistanceUnit {
        didSet { save(distanceUnit, forKey: Key.distanceUnit) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        alarm = Self.load(AlarmSettings.self, forKey: Key.alarm, from: defaults) ?? AlarmSettings()
        distanceUnit = Self.load(DistanceUnit.self, forKey: Key.distanceUnit, from: defaults) ?? .system
    }

    private func save(_ value: some Encodable, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load<Value: Decodable>(
        _ type: Value.Type,
        forKey key: String,
        from defaults: UserDefaults
    ) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

private enum Key {
    static let alarm = "alarmSettings"
    static let distanceUnit = "distanceUnit"
}
