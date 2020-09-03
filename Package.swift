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
    targets: [
        .target(
            name: "Proton",
            dependencies: [],
            path: "Proton/Sources"
        ),
        /*.testTarget(
            name: "ProtonTests",
            path: "Proton/Tests"
        )*/
    ]
)
