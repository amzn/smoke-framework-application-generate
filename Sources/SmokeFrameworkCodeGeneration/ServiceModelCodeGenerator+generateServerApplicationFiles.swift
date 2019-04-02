// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
    func generateServerApplicationFiles(generationType: GenerationType) {
        generateContainerServerApplicationHelper(generationType: generationType)
        generateContainerServerApplicationMain(generationType: generationType)
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
            
            import Foundation
            
            handleApplication()
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }

    private func generateContainerServerApplicationHelper(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let applicationSuffix = applicationDescription.applicationSuffix
        
        let fileName = "\(baseName)\(applicationSuffix).swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)\(applicationSuffix)"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            // \(baseName)\(applicationSuffix).swift
            // \(baseName)\(applicationSuffix)
            //
            
            import Foundation
            import \(baseName)OperationsHTTP1
            import \(baseName)Operations
            import SmokeHTTP1
            import SmokeOperationsHTTP1
            import SmokeAWSCore
            import LoggerAPI
            
            func handleApplication() {
                CloudwatchStandardErrorLogger.enableLogging()
            
                let operationsContext = \(baseName)OperationsContext()
            
                do {
                    let smokeHTTP1Server = try SmokeHTTP1Server.startAsOperationServer(
                        withHandlerSelector: createHandlerSelector(),
                        andContext: operationsContext)
            
                    try smokeHTTP1Server.waitUntilShutdownAndThen {
                        // TODO: Close/shutdown any clients or credentials that are part
                        //       of the operationsContext.
                    }
                } catch {
                    Log.error("Unable to start Operations Server: '\\(error)'")
                }
            }
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
            // swift-tools-version:4.2
            // The swift-tools-version declares the minimum version of Swift required to build this package.

            import PackageDescription

            let package = Package(
                name: "\(baseName)",
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
                    .package(url: "https://github.com/amzn/smoke-framework.git", .upToNextMajor(from: "0.8.0")),
                    .package(url: "https://github.com/amzn/smoke-aws-credentials.git", .upToNextMajor(from: "0.6.0")),
                    .package(url: "https://github.com/amzn/smoke-aws.git", .upToNextMajor(from: "0.16.32")),
                    ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(
                        name: "\(baseName)Model",
                        dependencies: ["SmokeOperations"]),
                    .target(
                        name: "\(baseName)Operations",
                        dependencies: ["\(baseName)Model"]),
                    .target(
                        name: "\(baseName)OperationsHTTP1",
                        dependencies: ["\(baseName)Operations", "SmokeOperationsHTTP1"]),
                    .target(
                        name: "\(baseName)Client",
                        dependencies: ["\(baseName)Model", "SmokeOperationsHTTP1", "SmokeAWSHttp"]),
                    .target(
                        name: "\(baseName)\(applicationSuffix)",
                        dependencies: ["\(baseName)OperationsHTTP1", "SmokeAWSCredentials"]),
                    .testTarget(
                        name: "\(baseName)OperationsTests",
                        dependencies: ["\(baseName)Operations"]),
                    ]
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
            *.xcodeproj
            *~
            """)
       
        fileBuilder.write(toFile: fileName, atFilePath: baseFilePath)
    }
}
