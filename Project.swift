import ProjectDescription

let project = Project(
    name: "PandaPAI",
    targets: [
        .target(
            name: "PandaPAI",
            destinations: [.iPhone, .mac],
            product: .app,
            bundleId: "example.com.pandapai",
            deploymentTargets: .multiplatform(iOS: "26.0",macOS: "15.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["PandaPAI/Sources/**"],
            resources: ["PandaPAI/Resources/**"],
            entitlements: "PandaPAI/PandaPAI.entitlements",
            dependencies: [
                .external(name: "Highlightr"),
                .external(name: "OmenTextField"),
                .external(name: "SwiftMath"),
                .external(name: "KeychainAccess"),
            ],
            settings: .settings(
                base: [
                    "MARKETING_VERSION": "2.2.0",
                    "CURRENT_PROJECT_VERSION": "2.2.0",
                    "SWIFT_VERSION": "5.0",
                    "ENABLE_HARDENED_RUNTIME": "YES",
                    "CODE_SIGN_STYLE": "Automatic",
                ]
            ),
            coreDataModels: [.coreDataModel("PandaPAI/macaiDataModel.xcdatamodeld")]
        ),
        .target(
            name: "PandaPAITests",
            destinations: [.iPhone, .mac],
            product: .unitTests,
            bundleId: "example.com.pandapai.tests",
            infoPlist: .default,
            sources: ["PandaPAITests/**"],
            dependencies: [.target(name: "PandaPAI")],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "PF5C6SD54S",
                    "SWIFT_VERSION": "5.0",
                ]
            )
        ),
        .target(
            name: "PandaPAIUITests",
            destinations: [.iPhone, .mac],
            product: .uiTests,
            bundleId: "example.com.pandapai.uitests",
            infoPlist: .default,
            sources: ["PandaPAIUITests/**"],
            dependencies: [.target(name: "PandaPAI")],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "5.0",
                ]
            )
        ),
    ]
)
