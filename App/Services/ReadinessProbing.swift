import ArrivalKit

@MainActor
protocol ReadinessProbing {
    func snapshot(for destination: Destination, settings: AlarmSettings) async -> ReadinessSnapshot
}
