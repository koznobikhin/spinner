// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Spinner",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Spinner", targets: ["Spinner"])
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "2.0.0")
    ],
    targets: [
        .target(name: "Spinner", dependencies: ["Rainbow", .product(name: "Signals", package: "BlueSignals")]),
        .testTarget(name: "SpinnerTests", dependencies: ["Spinner"]),
        .executableTarget(name: "Example", dependencies: ["Spinner", "Rainbow"]),
    ]
)
