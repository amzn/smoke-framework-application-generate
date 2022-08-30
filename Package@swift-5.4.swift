// swift-tools-version:5.4
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
    ],
    dependencies: [
        .package(name: "SmokeAWSGenerate",
                 url: "https://github.com/amzn/smoke-aws-generate.git", from: "3.0.0-beta.5"),
        .package(name: "ServiceModelSwiftCodeGenerate",
                 url: "https://github.com/amzn/service-model-swift-code-generate.git", from: "3.0.0-beta.10"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "SmokeFrameworkApplicationGenerate", dependencies: [
                .target(name: "SmokeFrameworkCodeGeneration"),
                .product(name: "OpenAPIServiceModel", package: "ServiceModelSwiftCodeGenerate"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "SmokeFrameworkCodeGeneration", dependencies: [
                .product(name: "ServiceModelGenerate", package: "ServiceModelSwiftCodeGenerate"),
                .product(name: "SmokeAWSModelGenerate", package: "SmokeAWSGenerate"),
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
