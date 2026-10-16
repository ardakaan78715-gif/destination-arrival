import ArrivalKit
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
}
