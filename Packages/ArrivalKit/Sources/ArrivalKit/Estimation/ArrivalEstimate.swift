import Foundation

public enum SpeedSource: Sendable, Equatable {
    case measured
    case assumed
}

public struct ArrivalEstimate: Sendable, Equatable {
    public let anchor: LocationSample
    public let distance: Double
    public let speed: Double
    public let speedSource: SpeedSource
    public let isMoving: Bool
    public let settings: AlarmSettings
    public let tuning: ArrivalTuning

    public init(
        anchor: LocationSample,
        destination: Destination,
        cruiseSpeed: Double?,
        isMoving: Bool,
        settings: AlarmSettings,
        tuning: ArrivalTuning = .standard
    ) {
        self.anchor = anchor
        self.distance = max(0, anchor.distance(to: destination) - anchor.horizontalAccuracy)
        if let cruiseSpeed, cruiseSpeed > 0 {
            self.speed = cruiseSpeed
            self.speedSource = .measured
        } else {
            self.speed = tuning.fastTrainSpeed
            self.speedSource = .assumed
        }
        self.isMoving = isMoving
        self.settings = settings
        self.tuning = tuning
    }

    public var projectionSpeed: Double {
        max(tuning.cautionFactor * speed, tuning.fastTrainSpeed)
    }

    public var alarmDistance: Double {
        max(speed * settings.leadTime, settings.radius)
    }

    public var alarmDate: Date {
        anchor.timestamp.addingTimeInterval(max(0, (distance - alarmDistance) / projectionSpeed))
    }

    public func distanceRemaining(at date: Date) -> Double {
        max(0, distance - projectionSpeed * elapsed(at: date))
    }

    public func timeRemaining(at date: Date) -> TimeInterval {
        distanceRemaining(at: date) / speed
    }

    public func isSignalLost(at date: Date) -> Bool {
        date.timeIntervalSince(anchor.timestamp) > tuning.signalLossAfter
    }

    public func isArmed(at date: Date) -> Bool {
        speedSource == .measured || isSignalLost(at: date)
    }

    public func alarmReason(at date: Date) -> AlarmReason? {
        if distance <= settings.radius {
            return .insideRadius
        }
        guard isArmed(at: date), date >= alarmDate else {
            return nil
        }
        return isSignalLost(at: date) ? .projectedDuringSignalLoss : .withinLeadTime
    }

    public func signalStatus(at date: Date) -> SignalStatus {
        if isSignalLost(at: date) {
            return .estimating(since: anchor.timestamp)
        }
        if speedSource == .assumed {
            return .waitingToMove
        }
        return isMoving ? .live : .stopped
    }

    private func elapsed(at date: Date) -> TimeInterval {
        max(0, date.timeIntervalSince(anchor.timestamp))
    }
}
