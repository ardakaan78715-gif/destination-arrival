import ArrivalKit
import Foundation
import Testing

@Suite struct AlarmSettingsTests {
    @Test func defaultsAreTwoMinutesAnd750Metres() {
        let settings = AlarmSettings()

        #expect(settings.leadTime == 120)
        #expect(settings.radius == 750)
    }

    @Test func radiusIsClampedToRange() {
        #expect(AlarmSettings(radius: 50).radius == 200)
        #expect(AlarmSettings(radius: 10_000).radius == 3_000)
    }

    @Test func radiusIsRoundedToTheStep() {
        #expect(AlarmSettings(radius: 1_234).radius == 1_250)
        #expect(AlarmSettings(radius: 1_210).radius == 1_200)
    }

    @Test func leadTimeSnapsToNearestChoice() {
        #expect(AlarmSettings(leadTime: 0).leadTime == 60)
        #expect(AlarmSettings(leadTime: 170).leadTime == 180)
        #expect(AlarmSettings(leadTime: 400).leadTime == 300)
        #expect(AlarmSettings(leadTime: 3_600).leadTime == 600)
    }

    @Test func codableRoundTrip() throws {
        let settings = AlarmSettings(leadTime: 300, radius: 1_200)

        let data = try JSONEncoder().encode(settings)

        #expect(try JSONDecoder().decode(AlarmSettings.self, from: data) == settings)
    }

    @Test func decodingClampsRadius() throws {
        let tooLarge = try decode(#"{"leadTime": 120, "radius": 99999}"#)
        let tooSmall = try decode(#"{"leadTime": 120, "radius": -40}"#)
        let offStep = try decode(#"{"leadTime": 120, "radius": 1234}"#)

        #expect(tooLarge.radius == 3_000)
        #expect(tooSmall.radius == 200)
        #expect(offStep.radius == 1_250)
    }

    @Test func decodingSnapsLeadTime() throws {
        let between = try decode(#"{"leadTime": 170, "radius": 750}"#)
        let negative = try decode(#"{"leadTime": -30, "radius": 750}"#)
        let tooLong = try decode(#"{"leadTime": 86400, "radius": 750}"#)

        #expect(between.leadTime == 180)
        #expect(negative.leadTime == 60)
        #expect(tooLong.leadTime == 600)
    }

    private func decode(_ json: String) throws -> AlarmSettings {
        try JSONDecoder().decode(AlarmSettings.self, from: Data(json.utf8))
    }
}
