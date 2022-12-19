// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebRequestOpenCombine",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "WebRequestOpenCombine",
            targets: ["WebRequestOpenCombine"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/TheAngryDarling/SwiftWebRequest.git",
                 from: "2.1.3"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git",
                 from: "0.13.0"),
        .package(url: "https://github.com/TheAngryDarling/SwiftLittleWebServer.git",
                 .exact( "0.1.6")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "WebRequestOpenCombine",
            dependencies: ["WebRequest", "OpenCombine"]),
        .testTarget(
            name: "WebRequestOpenCombineTests",
            dependencies: ["WebRequestOpenCombine", "LittleWebServer", "OpenCombine"]),
    ]
)
