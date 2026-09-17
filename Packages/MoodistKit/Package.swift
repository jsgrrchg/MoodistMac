// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MoodistKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v15), .iOS("26.0")],
    products: [.library(name: "MoodistKit", targets: ["MoodistKit"])],
    targets: [
        .target(name: "MoodistKit", resources: [.copy("Resources/sounds"), .process("Resources/PrivacyInfo.xcprivacy"), .process("Resources/en.lproj"), .process("Resources/es.lproj"), .process("Resources/pt-BR.lproj"), .process("Resources/SharedAssets.xcassets")]),
        .testTarget(name: "MoodistKitTests", dependencies: ["MoodistKit"])
    ],
    swiftLanguageModes: [.v5]
)
