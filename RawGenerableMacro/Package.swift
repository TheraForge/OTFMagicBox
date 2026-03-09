// swift-tools-version: 6.1
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "RawGenerableMacro",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "RawModel", targets: ["RawModel"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .macro(
            name: "RawGenerableMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        ),
        // What your app imports.
        .target(
            name: "RawModel",
            dependencies: ["RawGenerableMacros"]
        )
    ]
)
