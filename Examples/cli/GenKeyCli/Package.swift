// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "GenKeyCli",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.59.1"),
    .package(path: "../../.."),
  ],
  targets: [
    .executableTarget(
      name: "GenKeyCli",
      dependencies: [
        .product(name: "GenKey", package: "sw-genkey")
      ],
      swiftSettings: [
        .unsafeFlags(
          ["-cross-module-optimization"],
          .when(configuration: .release),
        )
      ],
    )
  ]
)
