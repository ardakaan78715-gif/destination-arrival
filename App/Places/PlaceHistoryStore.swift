import ArrivalKit
import Foundation
import Observation

@MainActor
@Observable
final class PlaceHistoryStore {
    private(set) var history: PlaceHistory

    @ObservationIgnored private let fileURL: URL?

    init(fileURL: URL? = PlaceHistoryStore.standardFileURL()) {
        self.fileURL = fileURL
        history = fileURL.flatMap(Self.load(from:)) ?? PlaceHistory()
    }

    func update(_ change: (inout PlaceHistory) -> Void) {
        change(&history)
        save()
    }

    nonisolated static func standardFileURL() -> URL? {
        let fileManager = FileManager.default
        guard let support = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            return nil
        }
        let folder = support.appending(path: "DestinationArrival", directoryHint: .isDirectory)
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        return folder.appending(path: "places.json", directoryHint: .notDirectory)
    }

    private func save() {
        guard let fileURL, let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from fileURL: URL) -> PlaceHistory? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(PlaceHistory.self, from: data)
    }
}
