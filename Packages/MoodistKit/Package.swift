// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoodistKit",
    platforms: [.macOS(.v15), .iOS("26.0")],
    products: [.library(name: "MoodistKit", targets: ["MoodistKit"])],
    targets: [
        .target(name: "MoodistKit"),
        .testTarget(name: "MoodistKitTests", dependencies: ["MoodistKit"])
    ],
    swiftLanguageModes: [.v5]
)
