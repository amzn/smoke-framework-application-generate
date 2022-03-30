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
//  ServiceModelCodeGenerator+generateHandlerSelector.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

extension ServiceModelCodeGenerator {
    /**
     Generate the hander selector for the operation handlers for the generated application.
     */
    func generateServerHanderSelector(operationStubGenerationRule: OperationStubGenerationRule,
                                      initializationType: InitializationType,
                                      eventLoopFutureOperationHandlers: CodeGenFeatureStatus) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        
        
        addGeneratedFileHeader(fileBuilder: fileBuilder)
        
        // build a map of http url to operation handler
        fileBuilder.appendLine("""
            // \(baseName)OperationsHanderSelector.swift
            // \(baseName)OperationsHTTP1
            //
            
            import Foundation
            import \(baseName)Model
            import \(baseName)Operations
            import SmokeOperations
            import SmokeOperationsHTTP1
            """)
        
        switch eventLoopFutureOperationHandlers {
        case .enabled:
            fileBuilder.appendLine("""
                import SmokeAsyncHTTP1

                """)
        case .disabled:
            fileBuilder.appendLine("""

                """)
        }
        
        fileBuilder.appendLine("""
            extension \(baseName)ModelOperations: OperationIdentity {}
            
            """)

        switch initializationType {
        case .original:
            fileBuilder.appendLine("""
                public func addOperations<SelectorType: SmokeHTTP1HandlerSelector>(selector: inout SelectorType)
                    where SelectorType.ContextType == \(baseName)OperationsContext,
                    SelectorType.OperationIdentifer == \(baseName)ModelOperations {
                """)
        case .streamlined:
            fileBuilder.appendLine("""
                public extension \(baseName)ModelOperations {
                    static func addToSmokeServer<SelectorType: SmokeHTTP1HandlerSelector>(selector: inout SelectorType)
                        where SelectorType.ContextType == \(baseName)OperationsContext,
                        SelectorType.OperationIdentifer == \(baseName)ModelOperations {
                """)
            fileBuilder.incIndent()
        }
        
        fileBuilder.incIndent()
        
        // sort the operations in alphabetical order for output
        let sortedOperations = model.operationDescriptions.sorted { entry1, entry2 in
            return entry1.key < entry2.key
        }
        
        // iterate through the operations
        for entry in sortedOperations {
            generateHandlerForOperation(name: entry.key, operationDescription: entry.value, baseName: baseName,
                                        fileBuilder: fileBuilder, operationStubGenerationRule: operationStubGenerationRule)
        }
        
        fileBuilder.decIndent()
        fileBuilder.appendLine("}")
        
        if case .streamlined = initializationType {
            fileBuilder.decIndent()
            fileBuilder.appendLine("}")
        }
        
        let fileName = "\(baseName)OperationsHanderSelector.swift"
        fileBuilder.write(toFile: fileName, atFilePath: "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1")
    }
    
    private func generateHandlerForOperation(name: String, operationDescription: OperationDescription,
                                             baseName: String, fileBuilder: FileBuilder,
                                             operationStubGenerationRule: OperationStubGenerationRule) {
        if let httpMethod = operationDescription.httpVerb {
            let sortedErrors = operationDescription.errors.sorted { entry1, entry2 in
                return entry1.code < entry2.code
            }
            
            var allowedErrors = ""
            for (index, error) in sortedErrors.enumerated() {
                let errorName = error.type.normalizedErrorName
                
                if index == 0 {
                    allowedErrors += "(.\(errorName), \(error.code))"
                } else {
                    allowedErrors += ", (.\(errorName), \(error.code))"
                }
            }
            
            let operationStubGeneration = operationStubGenerationRule.getStubGeneration(forOperation: name)

            let internalName = name.upperToLowerCamelCase
            
            fileBuilder.appendLine("""
                
                let allowedErrorsFor\(name.startingWithUppercase): [(\(baseName)ErrorTypes, Int)] = [\(allowedErrors)]
                """)
            
            switch operationStubGeneration {
            case .functionWithinContext:
                fileBuilder.appendLine("""
                    selector.addHandlerForOperationProvider(.\(internalName), httpMethod: .\(httpMethod),
                                                            operationProvider: \(baseName)OperationsContext.handle\(name.startingWithUppercase),
                                                            allowedErrors: allowedErrorsFor\(name.startingWithUppercase))
                    """)
            case .standaloneFunction:
                fileBuilder.appendLine("""
                    selector.addHandlerForOperation(.\(internalName), httpMethod: .\(httpMethod),
                                                    operation: handle\(name.startingWithUppercase),
                                                    allowedErrors: allowedErrorsFor\(name.startingWithUppercase))
                    """)
            }
        }
    }
}
