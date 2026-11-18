// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "onepassword-dialog-watcher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "onepassword-dialog-watcher", targets: ["onepassword-dialog-watcher"])
    ],
    targets: [
        .target(name: "OnePasswordDialogWatcherCore"),
        .executableTarget(
            name: "onepassword-dialog-watcher",
            dependencies: ["OnePasswordDialogWatcherCore"]
        ),
        // A plain executable rather than an XCTest target: nixpkgs' swiftpm
        // has no XCTest runner on macOS.
        .executableTarget(
            name: "onepassword-dialog-watcher-tests",
            dependencies: ["OnePasswordDialogWatcherCore"],
            path: "Tests/onepassword-dialog-watcher-tests"
        ),
    ]
)
