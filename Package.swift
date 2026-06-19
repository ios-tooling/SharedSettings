// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
	 name: "SharedSettings",
	  platforms: [
				  .macOS(.v14),
				  .iOS(.v17),
				  .tvOS(.v17),
				  .visionOS(.v1),
				  .watchOS(.v10)
			],
	 products: [
		  // Products define the executables and libraries produced by a package, and make them visible to other packages.
		  .library(
				name: "SharedSettings",
				targets: ["SharedSettings"]),
		  // Opt-in sugar: the @MemorySetting macro. Pulls in swift-syntax, so it lives
		  // in a separate product — `import SharedSettings` stays dependency-free.
		  .library(
				name: "SharedSettingsMacros",
				targets: ["SharedSettingsMacros"]),
	 ],
	 dependencies: [
		  .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
	 ],
	 targets: [
		  // Targets are the basic building blocks of a package. A target can define a module or a test suite.
		  // Targets can depend on other targets in this package, and on products in packages which this package depends on.
		  .target(name: "SharedSettings", dependencies: []),
		  .macro(
				name: "SharedSettingsMacroPlugin",
				dependencies: [
					 .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
					 .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				]),
		  .target(
				name: "SharedSettingsMacros",
				dependencies: ["SharedSettings", "SharedSettingsMacroPlugin"]),
		  .testTarget(
				name: "SharedSettingsTests",
				dependencies: ["SharedSettings"]),
		  .testTarget(
				name: "SharedSettingsMacrosTests",
				dependencies: ["SharedSettingsMacros"]),
	 ]
)
