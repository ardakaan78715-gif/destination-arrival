import ArrivalKit
import Foundation
import Testing

@Suite struct FixFilterTests {
    private let route = FixBuilder(speed: 15)

    @Test func rejectsNegativeAccuracy() {
        var filter = startedFilter()

        #expect(filter.accept(fix(afterMetres: 0, elapsed: 0, accuracy: -1)) == .invalidAccuracy)
        #expect(filter.lastAccepted == nil)
    }

    @Test func rejectsNonFiniteAccuracy() {
        var filter = startedFilter()

        #expect(filter.accept(fix(afterMetres: 0, elapsed: 0, accuracy: .nan)) == .invalidAccuracy)
        #expect(filter.accept(fix(afterMetres: 0, elapsed: 1, accuracy: .infinity)) == .invalidAccuracy)
        #expect(filter.lastAccepted == nil)
    }

    @Test func rejectsFixesWorseThan200Metres() {
        var filter = startedFilter()

        #expect(filter.accept(fix(afterMetres: 0, elapsed: 0, accuracy: 201)) == .tooInaccurate)
        #expect(filter.accept(fix(afterMetres: 0, elapsed: 1, accuracy: 200)) == .accepted)
    }

    @Test func rejectsStaleFixesFromBeforeStart() {
        var filter = startedFilter()

        #expect(filter.accept(fix(afterMetres: 0, elapsed: -61)) == .stale)
        #expect(filter.accept(fix(afterMetres: 0, elapsed: -30)) == .accepted)
    }

    @Test func rejectsOutOfOrderAndDuplicateTimestamps() {
        var filter = startedFilter()
        _ = filter.accept(fix(afterMetres: 150, elapsed: 10))

        #expect(filter.accept(fix(afterMetres: 150, elapsed: 10)) == .outOfOrder)
        #expect(filter.accept(fix(afterMetres: 75, elapsed: 5)) == .outOfOrder)
        #expect(filter.accept(fix(afterMetres: 165, elapsed: 11)) == .accepted)
    }

    @Test func rejectsImplausibleJumps() {
        var filter = startedFilter()
        let first = fix(afterMetres: 0, elapsed: 0)
        _ = filter.accept(first)

        #expect(filter.accept(fix(afterMetres: 1_000, elapsed: 1)) == .implausibleJump)
        #expect(filter.lastAccepted == first)
        #expect(filter.accept(fix(afterMetres: 50, elapsed: 2)) == .accepted)
    }

    @Test func acceptsLongJumpAfterTunnelGap() {
        var filter = startedFilter()
        _ = filter.accept(fix(afterMetres: 0, elapsed: 0))

        #expect(filter.accept(fix(afterMetres: 2_500, elapsed: 240)) == .accepted)
    }

    @Test func reportsTheFirstRuleThatFails() {
        var filter = startedFilter()

        #expect(filter.accept(fix(afterMetres: 0, elapsed: -120, accuracy: -5)) == .invalidAccuracy)
        #expect(filter.accept(fix(afterMetres: 0, elapsed: -120, accuracy: 500)) == .tooInaccurate)
    }

    private func startedFilter() -> FixFilter {
        FixFilter(journeyStart: FixBuilder.startDate)
    }

    private func fix(afterMetres metres: Double, elapsed: TimeInterval, accuracy: Double = 10) -> LocationSample {
        var sample = route.sample(afterMetres: metres, elapsed: elapsed)
        sample.horizontalAccuracy = accuracy
        return sample
    }
}
