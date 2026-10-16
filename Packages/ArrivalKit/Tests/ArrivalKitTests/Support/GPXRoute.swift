import ArrivalKit
import Foundation

struct GPXWaypoint: Equatable {
    var name: String
    var position: Waypoint
    var time: Date
    var isTunnel: Bool

    var destination: Destination {
        position.destination(named: name)
    }
}

struct GPXRoute {
    enum LoadError: Error {
        case malformed(line: Int)
    }

    private static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    var waypoints: [GPXWaypoint]

    var legs: [RouteLeg] {
        zip(waypoints, waypoints.dropFirst()).map { from, to in
            RouteLeg(from: from.position, to: to.position, start: from.time, end: to.time, isUnderground: from.isTunnel)
        }
    }

    var destination: Destination? {
        waypoints.last?.destination
    }

    static func load(_ name: String) throws -> GPXRoute {
        let file = repositoryRoot.appendingPathComponent("Simulation/\(name).gpx")
        return try GPXRoute(data: Data(contentsOf: file))
    }

    init(waypoints: [GPXWaypoint]) {
        self.waypoints = waypoints
    }

    init(data: Data) throws {
        let parser = XMLParser(data: data)
        let reader = WaypointReader()
        parser.delegate = reader
        guard parser.parse() else {
            throw LoadError.malformed(line: parser.lineNumber)
        }
        waypoints = reader.waypoints
    }

    func prefix(_ count: Int) -> GPXRoute {
        GPXRoute(waypoints: Array(waypoints.prefix(count)))
    }
}

private final class WaypointReader: NSObject, XMLParserDelegate {
    private struct Draft {
        var latitude: Double
        var longitude: Double
        var name: String?
        var time: Date?
        var type: String?
    }

    private let timestamps = ISO8601DateFormatter()
    private var draft: Draft?
    private var text = ""
    private(set) var waypoints: [GPXWaypoint] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        text = ""
        guard elementName == "wpt" else { return }
        guard let latitude = attributeDict["lat"].flatMap(Double.init),
              let longitude = attributeDict["lon"].flatMap(Double.init) else {
            parser.abortParsing()
            return
        }
        draft = Draft(latitude: latitude, longitude: longitude)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "time":
            draft?.time = timestamps.date(from: value)
        case "name":
            draft?.name = value
        case "type":
            draft?.type = value
        case "wpt":
            finishWaypoint(parser)
        default:
            break
        }
    }

    private func finishWaypoint(_ parser: XMLParser) {
        guard let draft, let name = draft.name, let time = draft.time else {
            parser.abortParsing()
            return
        }
        waypoints.append(GPXWaypoint(
            name: name,
            position: Waypoint(latitude: draft.latitude, longitude: draft.longitude),
            time: time,
            isTunnel: draft.type == "tunnel"
        ))
        self.draft = nil
    }
}
