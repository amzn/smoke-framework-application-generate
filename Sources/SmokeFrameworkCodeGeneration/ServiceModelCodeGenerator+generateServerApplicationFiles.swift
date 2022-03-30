// swiftlint:disable function_body_length
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
//
//  ServiceModelCodeGenerator+generateServerApplicationFiles.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator {
    /**
     Generate the main Swift file for the generated application as a Container Server.
     */
    func generateServerApplicationFiles(generationType: GenerationType,
                                        mainAnnotation: CodeGenFeatureStatus) {
        if case .disabled = mainAnnotation {
            generateContainerServerApplicationMain(generationType: generationType)
        }
        generatePackageFile(generationType: generationType)
        generateLintFile(generationType: generationType)
        generateGitIgnoreFile(generationType: generationType)
    }
    
    private func generateContainerServerApplicationMain(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        
        let fileName = "main.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)\(applicationSuffix)"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            // main.swift
            // \(baseName)\(applicationSuffix)
            //
            
            import SmokeHTTP1
            import SmokeOperationsHTTP1Server
            
            SmokeHTTP1Server.runAsOperationServer(\(baseName)PerInvocationContextInitializer.init)
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }

    private func generatePackageFile(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        
        let fileName = "Package.swift"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(baseFilePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            // swift-tools-version:5.5
            // The swift-tools-version declares the minimum version of Swift required to build this package.

            import PackageDescription

            let package = Package(
                name: "\(baseName)",
                platforms: [
                  .macOS(.v10_15), .iOS(.v10)
                ],
                products: [
                    // Products define the executables and libraries produced by a package, and make them visible to other packages.
                    .library(
                        name: "\(baseName)Model",
                        targets: ["\(baseName)Model"]),
                    .library(
                        name: "\(baseName)Client",
                        targets: ["\(baseName)Client"]),
                    .library(
                        name: "\(baseName)Operations",
                        targets: ["\(baseName)Operations"]),
                    .library(
                        name: "\(baseName)OperationsHTTP1",
                        targets: ["\(baseName)OperationsHTTP1"]),
                    .executable(
                        name: "\(baseName)\(applicationSuffix)",
                        targets: ["\(baseName)\(applicationSuffix)"]),
                    ],
                dependencies: [
                    .package(url: "https://github.com/amzn/smoke-framework.git", from: "2.7.0"),
                    .package(url: "https://github.com/amzn/smoke-aws-credentials.git", from: "2.0.0"),
                    .package(url: "https://github.com/amzn/smoke-aws.git", from: "2.0.0"),
                    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
                    ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(
                        name: "\(baseName)Model", dependencies: [
                            .product(name: "SmokeOperations", package: "smoke-framework"),
                            .product(name: "Logging", package: "swift-log"),
                        ]),
                    .target(
                        name: "\(baseName)Operations", dependencies: [
                            .target(name: "\(baseName)Model"),
                        ]),
                    .target(
                        name: "\(baseName)OperationsHTTP1", dependencies: [
                            .target(name: "\(baseName)Operations"),
                            .product(name: "SmokeOperationsHTTP1", package: "smoke-framework"),
                            .product(name: "SmokeOperationsHTTP1Server", package: "smoke-framework"),
                        ]),
                    .target(
                        name: "\(baseName)Client", dependencies: [
                            .target(name: "\(baseName)Model"),
                            .product(name: "SmokeOperationsHTTP1", package: "smoke-framework"),
                            .product(name: "SmokeAWSHttp", package: "smoke-aws"),
                        ]),
                    .executableTarget(
                        name: "\(baseName)\(applicationSuffix)", dependencies: [
                            .target(name: "\(baseName)OperationsHTTP1"),
                            .product(name: "SmokeAWSCredentials", package: "smoke-aws-credentials"),
                            .product(name: "SmokeOperationsHTTP1Server", package: "smoke-framework"),
                        ]),
                    .testTarget(
                        name: "\(baseName)OperationsTests", dependencies: [
                            .target(name: "\(baseName)Operations"),
                        ]),
                    ],
                    swiftLanguageVersions: [.v5]
            )
            """)

        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }

    func generateLintFile(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = ".swiftlint.yml"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(baseFilePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            disabled_rules:
              - trailing_whitespace
              - void_return
            included:
              - Sources
            line_length: 150
            function_body_length:
              warning: 50
              error: 75
            """)

        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }
    
    /**
     Create a basic .gitignore file that ignores standard build
     related files.
     */
    func generateGitIgnoreFile(generationType: GenerationType) {
       
        let fileBuilder = FileBuilder()
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = ".gitignore"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(baseFilePath)/\(fileName)") else {
                return
            }
        }
       
        fileBuilder.appendLine("""
            build
            .DS_Store
            .build/
            .swiftpm/
            *.xcodeproj
            *~
            """)
       
        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }
}
