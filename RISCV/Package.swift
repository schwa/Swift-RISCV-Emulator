// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RISCV",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "RISCV",
            targets: [
                "RISCV",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/schwa/Everything", "0.0.1"..<"0.0.3"),
    ],
    targets: [
        .target(
            name: "RISCV",
            dependencies: [
                .product(name: "Everything", package: "Everything")
            ]
        ),
        .testTarget(
            name: "RISCVTests",
            dependencies: ["RISCV"]),
    ]
)
