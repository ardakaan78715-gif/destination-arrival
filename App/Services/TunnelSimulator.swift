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

    func requestPermission() async -> Bool {
        await wrapped.requestPermission()
    }

    func start(precision: TrackingPrecision) -> AsyncStream<LocationSample> {
        let upstream = wrapped.start(precision: precision)
        let (stream, continuation) = AsyncStream.makeStream(
            of: LocationSample.self,
            bufferingPolicy: .bufferingNewest(16)
        )
        forwarding?.cancel()
        forwarding = Task { [weak self] in
            for await sample in upstream {
                guard let self else { break }
                if !isInTunnel {
                    continuation.yield(sample)
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
}
