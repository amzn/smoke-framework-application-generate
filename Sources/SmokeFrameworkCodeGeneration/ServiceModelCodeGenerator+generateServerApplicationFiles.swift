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

extension ServiceModelCodeGenerator where TargetSupportType: ModelTargetSupport & ClientTargetSupport & HTTP1IntegrationTargetSupport {
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
        
        if generationType.isUpdate {
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
        let modelTargetName = self.targetSupport.modelTargetName
        let clientTargetName = self.targetSupport.clientTargetName
        let http1IntegrationTargetName = self.targetSupport.http1IntegrationTargetName
        
        let fileName = "Package.swift"
        
        if generationType.isUpdate {
            guard !FileManager.default.fileExists(atPath: "\(baseFilePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            // swift-tools-version:5.6
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
                        name: "\(modelTargetName)",
                        targets: ["\(modelTargetName)"]),
                    .library(
                        name: "\(clientTargetName)",
                        targets: ["\(clientTargetName)"]),
                    .library(
                        name: "\(baseName)Operations",
                        targets: ["\(baseName)Operations"]),
                    .library(
                        name: "\(http1IntegrationTargetName)",
                        targets: ["\(http1IntegrationTargetName)"]),
                    .executable(
                        name: "\(baseName)\(applicationSuffix)",
                        targets: ["\(baseName)\(applicationSuffix)"]),
                    ],
                dependencies: [
                    .package(url: "https://github.com/amzn/smoke-framework.git", from: "2.7.0"),
                    .package(url: "https://github.com/amzn/smoke-aws-credentials.git", from: "2.0.0"),
                    .package(url: "https://github.com/amzn/smoke-aws-support.git", from: "1.0.0"),
                    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
            """)
        
        if case .serverWithPlugin = generationType {
            fileBuilder.appendLine("""
                        .package(url: "https://github.com/amzn/smoke-framework-application-generate", from: "3.0.0-beta.1")
                """)
        }
        
        fileBuilder.appendLine("""
                    ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(
                        name: "\(modelTargetName)", dependencies: [
                            .product(name: "SmokeOperations", package: "smoke-framework"),
                            .product(name: "Logging", package: "swift-log"),
            """)
        
        if case .serverWithPlugin = generationType {
            fileBuilder.appendLine("""
                            ],
                            plugins: [
                                .plugin(name: "SmokeFrameworkGenerateModel", package: "smoke-framework-application-generate")
                """)
        }
        
        fileBuilder.appendLine("""
                        ]),
                    .target(
                        name: "\(baseName)Operations", dependencies: [
                            .target(name: "\(modelTargetName)"),
                        ]),
                    .target(
                        name: "\(http1IntegrationTargetName)", dependencies: [
                            .target(name: "\(baseName)Operations"),
                            .product(name: "SmokeOperationsHTTP1", package: "smoke-framework"),
                            .product(name: "SmokeOperationsHTTP1Server", package: "smoke-framework"),
            """)
        
        if case .serverWithPlugin = generationType {
            fileBuilder.appendLine("""
                            ],
                            plugins: [
                                .plugin(name: "SmokeFrameworkGenerateHttp1", package: "smoke-framework-application-generate")
                """)
        }
        
        fileBuilder.appendLine("""
                        ]),
                    .target(
                        name: "\(clientTargetName)", dependencies: [
                            .target(name: "\(modelTargetName)"),
                            .product(name: "SmokeOperationsHTTP1", package: "smoke-framework"),
                            .product(name: "AWSHttp", package: "smoke-aws-support"),
            """)
        
        if case .serverWithPlugin = generationType {
            fileBuilder.appendLine("""
                            ],
                            plugins: [
                                .plugin(name: "SmokeFrameworkGenerateClient", package: "smoke-framework-application-generate")
                """)
        }
        
        fileBuilder.appendLine("""
                        ]),
                    .executableTarget(
                        name: "\(baseName)\(applicationSuffix)", dependencies: [
                            .target(name: "\(http1IntegrationTargetName)"),
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
        
        if generationType.isUpdate {
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
        
        if generationType.isUpdate {
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
