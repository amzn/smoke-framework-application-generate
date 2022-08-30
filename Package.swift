// swift-tools-version:5.6
//
// Copyright 2019-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import PackageDescription

let package = Package(
    name: "SmokeFrameworkApplicationGenerate",
    platforms: [
        .macOS(.v10_15), .iOS(.v10)
    ],
    products: [
        .executable(
            name: "SmokeFrameworkApplicationGenerate",
            targets: ["SmokeFrameworkApplicationGenerate"]),
        .library(
            name: "SmokeFrameworkCodeGeneration",
            targets: ["SmokeFrameworkCodeGeneration"]),
        .plugin(
            name: "SmokeFrameworkGenerateModel",
            targets: ["SmokeFrameworkGenerateModel"]),
        .plugin(
            name: "SmokeFrameworkGenerateClient",
            targets: ["SmokeFrameworkGenerateClient"]),
        .plugin(
            name: "SmokeFrameworkGenerateHttp1",
            targets: ["SmokeFrameworkGenerateHttp1"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amzn/smoke-aws-generate.git", from: "3.0.0-beta.5"),
        .package(url: "https://github.com/amzn/service-model-swift-code-generate.git", from: "3.0.0-beta.10"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .plugin(
            name: "SmokeFrameworkGenerateModel",
            capability: .buildTool(),
            dependencies: ["SmokeFrameworkApplicationGenerate"]
        ),
        .plugin(
            name: "SmokeFrameworkGenerateClient",
            capability: .buildTool(),
            dependencies: ["SmokeFrameworkApplicationGenerate"]
        ),
        .plugin(
            name: "SmokeFrameworkGenerateHttp1",
            capability: .buildTool(),
            dependencies: ["SmokeFrameworkApplicationGenerate"]
        ),
        .executableTarget(
            name: "SmokeFrameworkApplicationGenerate", dependencies: [
                .target(name: "SmokeFrameworkCodeGeneration"),
                .product(name: "OpenAPIServiceModel", package: "service-model-swift-code-generate"),
            ]
        ),
        .target(
            name: "SmokeFrameworkCodeGeneration", dependencies: [
                .product(name: "ServiceModelGenerate", package: "service-model-swift-code-generate"),
                .product(name: "SmokeAWSModelGenerate", package: "smoke-aws-generate"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "CodeGenerateTests", dependencies: [
                .target(name: "SmokeFrameworkApplicationGenerate"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
