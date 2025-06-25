// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "GenKey",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "GenKey",
      targets: ["GenKey"])
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.59.1"),
    .package(
      url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.4",
    ),
  ],
  targets: [
    .target(
      name: "GenKey"),
    .testTarget(
      name: "GenKeyTests",
      dependencies: ["GenKey"],
      resources: [
        // These values are found in a wikipedia page(HKDF).
        // Do NOT embed real secrets.
        .embedInCode("./.testData/deriveKey/.secret/ikm.dat"),
        .embedInCode("./.testData/deriveKey/salt.dat"),
        .embedInCode("./.testData/deriveKey/info.dat"),
        .embedInCode("./.testData/deriveKey/expected.dat"),
      ],
    ),
  ]
)
