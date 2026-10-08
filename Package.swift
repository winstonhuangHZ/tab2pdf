// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Tab2PDF",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Tab2PDF",
            path: "Sources/Tab2PDF",
            resources: [.copy("Resources/gp2pdf.jar")]
        )
    ]
)
