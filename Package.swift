// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "stool",
    products: [
        .executable(name: "stool", targets: ["STool"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/kylef/Commander", from: "0.9.1"),
        .package(url: "https://github.com/Hejki/Commander", .branch("master")),
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.13.0"),
        .package(url: "https://github.com/Hejki/CommandLineAPI", from: "0.3.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "2.0.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "8.0.4"),
    ],
    targets: [
        .target(
            name: "STool",
            dependencies: ["Commander", "CommandLineAPI", "Stencil", "Yams"],
            path: "Sources"
        ),
        .testTarget(
            name: "SToolTests",
            dependencies: ["STool", "Nimble"]
        ),
    ]
)
