import ArrivalKit
import Observation

@MainActor
@Observable
final class TunnelSimulator: LocationService {
    var isInTunnel = false

    @ObservationIgnored private let wrapped: any LocationService
    @ObservationIgnored private var forwarding: Task<Void, Never>?

    init(wrapping wrapped: any LocationService) {
        self.wrapped = wrapped
    }

    var lastKnownSample: LocationSample? {
        wrapped.lastKnownSample
    }

    func requestPermission() async -> Bool {
        await wrapped.requestPermission()
    }

    func start(precision: TrackingPrecision) -> AsyncStream<LocationUpdate> {
        let upstream = wrapped.start(precision: precision)
        let (stream, continuation) = AsyncStream.makeStream(
            of: LocationUpdate.self,
            bufferingPolicy: .bufferingNewest(16)
        )
        forwarding?.cancel()
        forwarding = Task { [weak self] in
            for await update in upstream {
                guard let self else { break }
                if !blocks(update) {
                    continuation.yield(update)
                }
            }
            continuation.finish()
        }
        return stream
    }

    func setPrecision(_ precision: TrackingPrecision) {
        wrapped.setPrecision(precision)
    }

    func stop() {
        wrapped.stop()
        forwarding?.cancel()
        forwarding = nil
        isInTunnel = false
    }

    private func blocks(_ update: LocationUpdate) -> Bool {
        switch update {
        case .sample:
            isInTunnel
        case .accessLost:
            false
        }
    }
}
