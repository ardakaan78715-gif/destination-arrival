// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ArrivalKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ArrivalKit", targets: ["ArrivalKit"])
    ],
    targets: [
        .target(name: "ArrivalKit"),
        .testTarget(name: "ArrivalKitTests", dependencies: ["ArrivalKit"])
    ]
)
