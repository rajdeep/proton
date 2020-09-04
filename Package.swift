// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Proton",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "Proton", targets: ["Proton"])
    ],
    dependencies: [
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Proton",
            dependencies: [],
            path: "Proton/Sources"
        ),
        .testTarget(
            name: "ProtonTests",
            dependencies: ["Proton", "SnapshotTesting"],
            path: "Proton/Tests"
        )
    ]
)
