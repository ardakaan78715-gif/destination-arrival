import Foundation

public struct PlaceHistory: Sendable, Codable, Equatable {
    public static let recentsLimit = 8
    public static let samePlaceDistance: Double = 50

    public private(set) var favourites: [Destination] = []
    public private(set) var recents: [Destination] = []

    public init() {}

    public var isEmpty: Bool {
        favourites.isEmpty && recents.isEmpty
    }

    public func isFavourite(_ place: Destination) -> Bool {
        favourites.contains { $0.isSamePlace(as: place) }
    }

    public mutating func recordJourney(to place: Destination) {
        recents.removeAll { $0.isSamePlace(as: place) }
        guard !isFavourite(place) else { return }
        recents.insert(place, at: 0)
        recents = Array(recents.prefix(Self.recentsLimit))
    }

    public mutating func toggleFavourite(_ place: Destination) {
        if isFavourite(place) {
            favourites.removeAll { $0.isSamePlace(as: place) }
        } else {
            favourites.append(place)
            recents.removeAll { $0.isSamePlace(as: place) }
        }
    }

    public mutating func remove(_ place: Destination) {
        favourites.removeAll { $0.isSamePlace(as: place) }
        recents.removeAll { $0.isSamePlace(as: place) }
    }
}

private extension Destination {
    func isSamePlace(as other: Destination) -> Bool {
        location.distance(from: other.location) <= PlaceHistory.samePlaceDistance
    }
}
