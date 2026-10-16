import ArrivalKit
import Foundation
import Testing

@Suite struct ReadinessTests {
    private let allClear = ReadinessSnapshot(
        location: .whenInUse,
        hasPreciseLocation: true,
        notifications: .allowed,
        isLowPowerModeOn: false,
        isVolumeLow: false,
        distanceToDestination: 4_000,
        radius: 750
    )
    private let bakerStreet = Destination(name: "Baker Street", latitude: 51.5226, longitude: -0.1571)

    @Test func allClearHasNoIssues() {
        var alwaysAllowed = allClear
        alwaysAllowed.location = .always
        var unknownDistance = allClear
        unknownDistance.distanceToDestination = nil

        #expect(Readiness.issues(for: allClear).isEmpty)
        #expect(Readiness.issues(for: alwaysAllowed).isEmpty)
        #expect(Readiness.issues(for: unknownDistance).isEmpty)
    }

    @Test func deniedLocationBlocks() {
        var snapshot = allClear
        snapshot.location = .denied

        #expect(Readiness.issues(for: snapshot) == [.locationDenied])
        #expect(ReadinessIssue.locationDenied.isBlocking)
    }

    @Test func restrictedLocationBlocks() {
        var snapshot = allClear
        snapshot.location = .restricted

        #expect(Readiness.issues(for: snapshot) == [.locationRestricted])
        #expect(ReadinessIssue.locationRestricted.isBlocking)
    }

    @Test func alreadyInsideRadiusBlocks() {
        var inside = allClear
        inside.distanceToDestination = 600
        var onTheEdge = allClear
        onTheEdge.distanceToDestination = 750
        var justOutside = allClear
        justOutside.distanceToDestination = 760

        #expect(Readiness.issues(for: inside) == [.alreadyThere])
        #expect(Readiness.issues(for: onTheEdge) == [.alreadyThere])
        #expect(Readiness.issues(for: justOutside).isEmpty)
        #expect(ReadinessIssue.alreadyThere.isBlocking)
    }

    @Test func approximateLocationWarns() {
        var snapshot = allClear
        snapshot.hasPreciseLocation = false

        #expect(Readiness.issues(for: snapshot) == [.approximateLocation])
        #expect(!ReadinessIssue.approximateLocation.isBlocking)
    }

    @Test func approximateLocationNeedsLocationAccess() {
        var denied = allClear
        denied.location = .denied
        denied.hasPreciseLocation = false
        var undetermined = allClear
        undetermined.location = .notDetermined
        undetermined.hasPreciseLocation = false

        #expect(Readiness.issues(for: denied) == [.locationDenied])
        #expect(Readiness.issues(for: undetermined).isEmpty)
    }

    @Test func notificationsDeniedWarns() {
        var snapshot = allClear
        snapshot.notifications = .denied

        #expect(Readiness.issues(for: snapshot) == [.notificationsDenied])
        #expect(!ReadinessIssue.notificationsDenied.isBlocking)
    }

    @Test func lowPowerModeWarns() {
        var snapshot = allClear
        snapshot.isLowPowerModeOn = true

        #expect(Readiness.issues(for: snapshot) == [.lowPowerMode])
        #expect(!ReadinessIssue.lowPowerMode.isBlocking)
    }

    @Test func lowVolumeWarns() {
        var snapshot = allClear
        snapshot.isVolumeLow = true

        #expect(Readiness.issues(for: snapshot) == [.volumeLow])
        #expect(!ReadinessIssue.volumeLow.isBlocking)
    }

    @Test func blockersComeFirst() {
        let everythingWrong = ReadinessSnapshot(
            location: .whenInUse,
            hasPreciseLocation: false,
            notifications: .denied,
            isLowPowerModeOn: true,
            isVolumeLow: true,
            distanceToDestination: 100,
            radius: 750
        )
        var deniedToo = everythingWrong
        deniedToo.location = .denied

        let issues = Readiness.issues(for: everythingWrong)

        #expect(issues == [.alreadyThere, .approximateLocation, .notificationsDenied, .lowPowerMode, .volumeLow])
        #expect(issues.first?.isBlocking == true)
        #expect(issues.dropFirst().allSatisfy { !$0.isBlocking })
        #expect(Readiness.issues(for: deniedToo) == [
            .locationDenied, .alreadyThere, .notificationsDenied, .lowPowerMode, .volumeLow
        ])
    }

    @Test func undeterminedPermissionsAreNotIssues() {
        var snapshot = allClear
        snapshot.location = .notDetermined
        snapshot.notifications = .notDetermined

        #expect(Readiness.issues(for: snapshot).isEmpty)
    }

    @Test func distanceComesFromACurrentFix() throws {
        let now = FixBuilder.startDate
        let fix = LocationSample(latitude: 51.5300, longitude: -0.1700, horizontalAccuracy: 40, timestamp: now - 30)

        let distance = try #require(Readiness.distance(from: fix, to: bakerStreet, at: now))

        #expect(distance == fix.distance(to: bakerStreet) - 40)
        #expect(abs(distance - 1_175) < 25)
    }

    @Test func staleCoarseOrMissingFixesGiveNoDistance() {
        let now = FixBuilder.startDate
        let stale = LocationSample(latitude: 51.5226, longitude: -0.1571, horizontalAccuracy: 10, timestamp: now - 120)
        let coarse = LocationSample(latitude: 51.5226, longitude: -0.1571, horizontalAccuracy: 1_500, timestamp: now)

        #expect(Readiness.distance(from: stale, to: bakerStreet, at: now) == nil)
        #expect(Readiness.distance(from: coarse, to: bakerStreet, at: now) == nil)
        #expect(Readiness.distance(from: nil, to: bakerStreet, at: now) == nil)
    }
}
