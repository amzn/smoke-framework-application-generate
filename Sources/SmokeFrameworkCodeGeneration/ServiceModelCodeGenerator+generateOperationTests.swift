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
//  ServiceModelCodeGenerator+generateOperationTests.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

extension ServiceModelCodeGenerator {
    private func generateExampleTestCase(operationDescription: OperationDescription, name: String,
                                         input: String, fileBuilder: FileBuilder,
                                         operationStubGeneration: OperationStubGeneration,
                                         asyncOperationStubs: CodeGenFeatureStatus) {
        let tryPrefix = !operationDescription.errors.isEmpty ? "try " : ""
        let throwsPrefix = !operationDescription.errors.isEmpty ? " throws" : ""

        let asyncInfix: String
        let awaitInfix: String
        switch asyncOperationStubs {
        case .disabled:
            asyncInfix = ""
            awaitInfix = ""
        case .enabled:
            asyncInfix = " async"
            awaitInfix = "await "
        }
        
        // append the body of the test for this operation.
        fileBuilder.appendLine("""
            func test\(name)()\(asyncInfix)\(throwsPrefix) {
                let input = \(input).__default
                let operationsContext = createOperationsContext()
            
            """)
        
        switch operationStubGeneration {
        case .functionWithinContext:
            if let output = operationDescription.output {
                fileBuilder.appendLine("""
                        let response = \(tryPrefix)\(awaitInfix)operationsContext.handle\(name)(input: input)
                        XCTAssertEqual(response, \(output).__default)
                    }
                    """)
            } else {
                fileBuilder.appendLine("""
                        \(tryPrefix)\(awaitInfix)operationsContext.handle\(name)(input: input)
                    }
                    """)
            }
        case .standaloneFunction:
            if let output = operationDescription.output {
                fileBuilder.appendLine("""
                        let response = \(tryPrefix)\(awaitInfix)handle\(name)(input: input, context: operationsContext)
                        XCTAssertEqual(response, \(output).__default)
                    }
                    """)
            } else {
                fileBuilder.appendLine("""
                        \(tryPrefix)\(awaitInfix)handle\(name)(input: input, context: operationsContext)
                    }
                    """)
            }
        }
    }
    
    /**
     Generate the example operation unit tests for the generated application.
     */
    func generateOperationTests(generationType: GenerationType, operationStubGenerationRule: OperationStubGenerationRule,
                                asyncOperationStubs: CodeGenFeatureStatus, testDiscovery: CodeGenFeatureStatus) {
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let filePath = "\(baseFilePath)/Tests/\(baseName)OperationsTests"
        
        // iterate through each operation
        for (operationName, operationDescription) in model.operationDescriptions {
            let name = operationName.startingWithUppercase
            // skip this operation if it doesn't have an
            // input structure or output structure
            guard let input = operationDescription.input else {
                continue
            }
            
            let fileName = "\(name)Tests.swift"
            
            if case .serverUpdate = generationType {
                guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                    continue
                }
            }
            
            let fileBuilder = FileBuilder()
            
            fileBuilder.appendLine("""
                //
                // \(name)Tests.swift
                // \(baseName)OperationsTests
                //
                
                import XCTest
                @testable import \(baseName)Operations
                import \(baseName)Model
                
                class \(name)Tests: XCTestCase {
                
                """)
            
            fileBuilder.incIndent()
            
            let operationStubGeneration = operationStubGenerationRule.getStubGeneration(forOperation: operationName)
            generateExampleTestCase(operationDescription: operationDescription, name: name, input: input,
                                    fileBuilder: fileBuilder, operationStubGeneration: operationStubGeneration,
                                    asyncOperationStubs: asyncOperationStubs)
            
            if case .disabled = testDiscovery {
                // append the allTests list
                fileBuilder.appendEmptyLine()
                fileBuilder.appendLine("""
                    static var allTests = [
                        ("test\(name)", test\(name)),
                    ]
                    """)
            }
            
            fileBuilder.appendLine("}", preDec: true)
        
            fileBuilder.write(toFile: fileName,
                              atFilePath: filePath)
        }
    }
}
