// swift-tools-version: 6.0

// provides the types used to describe a Swift package
import PackageDescription

// defines how Swift Package Manager builds TaskReceipt
let package = Package(
    // sets the package and application name
    name: "TaskReceipt",
    // limits the app to macOS 14 or newer
    platforms: [
        .macOS(.v14)
    ],
    // produces a runnable TaskReceipt executable
    products: [
        .executable(
            name: "TaskReceipt",
            targets: ["TaskReceipt"]
        )
    ],
    // downloads the firebase libraries used for authentication and history
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "13.1.1"
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS.git",
            from: "10.0.0"
        )
    ],
    // builds the source files in Sources/TaskReceipt as one target
    targets: [
        .executableTarget(
            name: "TaskReceipt",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS")
            ]
        )
    ]
)
