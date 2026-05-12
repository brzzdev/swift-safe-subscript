// swift-tools-version: 6.3
import PackageDescription

let package = Package(
	name: "swift-safe-subscript",
	platforms: [
		.iOS(.v13),
		.macCatalyst(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.visionOS(.v1),
		.watchOS(.v6),
	],
	products: [
		.library(
			name: "SafeSubscript",
			targets: ["SafeSubscript"],
		),
	],
	targets: [
		.target(name: "SafeSubscript"),
		.testTarget(
			name: "SafeSubscriptTests",
			dependencies: ["SafeSubscript"],
		),
		.executableTarget(
			name: "SafeSubscriptBenchmarks",
			dependencies: ["SafeSubscript"],
		),
	],
)
