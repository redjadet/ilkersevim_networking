// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "IlkerSevimNetworking",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .watchOS(.v10),
  ],
  products: [
    .library(name: "IlkerSevimNetworking", targets: ["IlkerSevimNetworking"]),
  ],
  targets: [
    .target(name: "IlkerSevimNetworking"),
    .testTarget(
      name: "IlkerSevimNetworkingTests",
      dependencies: ["IlkerSevimNetworking"]
    ),
  ]
)
