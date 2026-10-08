// swift-tools-version: 6.0
// VijfKit: the rules and data shared by the iOS and watchOS apps. No UI.
import PackageDescription

let package = Package(
    name: "VijfKit",
    platforms: [.iOS(.v18), .watchOS(.v11), .macOS(.v15)],
    products: [
        .library(name: "VijfKit", targets: ["VijfKit"])
    ],
    targets: [
        .target(name: "VijfKit"),
        .testTarget(name: "VijfKitTests", dependencies: ["VijfKit"])
    ]
)
