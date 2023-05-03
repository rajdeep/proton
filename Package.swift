// swift-tools-version:5.2
//
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import PackageDescription

let package = Package(
    name: "Proton",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(name: "Proton", targets: ["Proton"]),
        .library(name: "ProtonCore", targets: ["ProtonCore"])
    ],
    dependencies: [
        .package(name: "SnapshotTesting", url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "ProtonCore",
            dependencies: [],
            path: "Proton/Sources/ObjC"         
        ),
        .target(
            name: "Proton",
            dependencies: ["ProtonCore"],
            path: "Proton/Sources/Swift"
        ),
        .testTarget(
            name: "ProtonTests",
            dependencies: ["Proton", "SnapshotTesting"],
            path: "Proton/Tests"
        )
    ]
)
