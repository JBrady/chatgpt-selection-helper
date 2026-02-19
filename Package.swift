// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "chatgpt-selection-helper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "chatgpt-selection-helper", targets: ["ChatGPTSelectionHelper"])
    ],
    targets: [
        .executableTarget(
            name: "ChatGPTSelectionHelper",
            path: "Sources/ChatGPTSelectionHelper"
        ),
        .testTarget(
            name: "ChatGPTSelectionHelperTests",
            dependencies: ["ChatGPTSelectionHelper"],
            path: "Tests/ChatGPTSelectionHelperTests"
        )
    ]
)
