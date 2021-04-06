// swift-tools-version:5.0
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
    products: [
        .executable(
            name: "SmokeFrameworkApplicationGenerate",
            targets: ["SmokeFrameworkApplicationGenerate"]),
        .library(
            name: "SmokeFrameworkCodeGeneration",
            targets: ["SmokeFrameworkCodeGeneration"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amzn/smoke-aws-generate.git", from: "2.1.0"),
        .package(url: "https://github.com/amzn/service-model-swift-code-generate.git", from: "2.3.1"),
    ],
    targets: [
        .target(
            name: "SmokeFrameworkApplicationGenerate",
            dependencies: ["SmokeFrameworkCodeGeneration"]),
        .target(
            name: "SmokeFrameworkCodeGeneration",
            dependencies: ["ServiceModelGenerate", "SmokeAWSModelGenerate"]),
    ]
)
