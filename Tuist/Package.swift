// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "PandaPAI",
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr", branch: "master"),
        .package(url: "https://github.com/Renset/OmenTextField", branch: "main"),
        .package(url: "https://github.com/mgriebling/SwiftMath", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", branch: "master")
    ]
)