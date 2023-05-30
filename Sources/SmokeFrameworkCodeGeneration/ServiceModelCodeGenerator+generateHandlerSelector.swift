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

extension ServiceModelCodeGenerator where TargetSupportType: HTTP1IntegrationTargetSupport {
    /**
     Generate the hander selector for the operation handlers for the generated application.
     */
    func generateServerHanderSelector(operationStubGenerationRule: OperationStubGenerationRule,
                                      initializationType: InitializationType,
                                      contextTypeName: String,
                                      eventLoopFutureOperationHandlers: CodeGenFeatureStatus) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let http1IntegrationTargetName = self.targetSupport.http1IntegrationTargetName
        
        
        addGeneratedFileHeader(fileBuilder: fileBuilder)
        
        // build a map of http url to operation handler
        fileBuilder.appendLine("""
            // \(baseName)OperationsHanderSelector.swift
            // \(http1IntegrationTargetName)
            //
            
            import Foundation
            import \(baseName)Model
            import \(baseName)Operations
            import SmokeOperations
            import SmokeOperationsHTTP1
            """)
        
        if case .v3 = initializationType {
            fileBuilder.appendLine("""
                import SmokeOperationsHTTP1Server
                """)
        }
        
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

        let selectorName: String
        let requiresTransformMiddleware: Bool
        switch initializationType {
        case .original:
            fileBuilder.appendLine("""
                public func addOperations<SelectorType: SmokeHTTP1HandlerSelector>(selector: inout SelectorType)
                    where SelectorType.ContextType == \(contextTypeName),
                    SelectorType.OperationIdentifer == \(baseName)ModelOperations {
                """)
            
            selectorName = "selector"
            requiresTransformMiddleware = false
        case .streamlined:
            fileBuilder.appendLine("""
                public extension \(baseName)ModelOperations {
                    static func addToSmokeServer<SelectorType: SmokeHTTP1HandlerSelector>(selector: inout SelectorType)
                        where SelectorType.ContextType == \(contextTypeName),
                        SelectorType.OperationIdentifer == \(baseName)ModelOperations {
                """)
            fileBuilder.incIndent()
            
            selectorName = "selector"
            requiresTransformMiddleware = false
        case .v3:
            fileBuilder.appendLine("""
                public extension \(baseName)ModelOperations {
                    static func addToSmokeServer<MiddlewareStackType: ServerMiddlewareStackProtocol>(stack: inout MiddlewareStackType)
                        where MiddlewareStackType.ApplicationContextType == \(contextTypeName),
                        MiddlewareStackType.RouterType.OperationIdentifer == \(baseName)ModelOperations {
                """)
            fileBuilder.incIndent()
            
            selectorName = "stack"
            requiresTransformMiddleware = true
        }
        
        fileBuilder.incIndent()
        
        // sort the operations in alphabetical order for output
        let sortedOperations = model.operationDescriptions.sorted { entry1, entry2 in
            return entry1.key < entry2.key
        }
        
        // iterate through the operations
        for entry in sortedOperations {
            generateHandlerForOperation(name: entry.key, operationDescription: entry.value, baseName: baseName,
                                        fileBuilder: fileBuilder, selectorName: selectorName,
                                        requiresTransformMiddleware: requiresTransformMiddleware,
                                        operationStubGenerationRule: operationStubGenerationRule)
        }
        
        fileBuilder.decIndent()
        fileBuilder.appendLine("}")
        
        switch initializationType {
        case .streamlined, .v3:
            fileBuilder.decIndent()
            fileBuilder.appendLine("}")
        case .original:
            // nothing to do
            break
        }
        
        let fileName = "\(baseName)OperationsHanderSelector.swift"
        fileBuilder.write(toFile: fileName, atFilePath: "\(baseFilePath)/Sources/\(http1IntegrationTargetName)")
    }
    
    private func generateHandlerForOperation(name: String, operationDescription: OperationDescription,
                                             baseName: String, fileBuilder: FileBuilder,
                                             selectorName: String, requiresTransformMiddleware: Bool,
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
            
            if requiresTransformMiddleware {
                let transformMiddleware: String
                switch (operationDescription.input, operationDescription.output) {
                case (.none, .none):
                    transformMiddleware = "VoidTransformingMiddleware.withNoInputNoOutput"
                case (.some, .none):
                    transformMiddleware = "JSONTransformingMiddleware.withInputAndWithNoOutput"
                case (.none, .some):
                    transformMiddleware = "JSONTransformingMiddleware.withNoInputAndWithOutput"
                case (.some, .some):
                    transformMiddleware = "JSONTransformingMiddleware.withInputAndWithOutput"
                }
                
                switch operationStubGeneration {
                case .functionWithinContext:
                    fileBuilder.appendLine("""
                        \(selectorName).addHandlerForOperationProvider(
                            .\(internalName), httpMethod: .\(httpMethod),
                            operationProvider: \(baseName)OperationsContext.handle\(name.startingWithUppercase),
                            allowedErrors: allowedErrorsFor\(name.startingWithUppercase),
                            transformMiddleware: \(transformMiddleware)(statusOnSuccess: .ok))
                        """)
                case .standaloneFunction:
                    fileBuilder.appendLine("""
                        \(selectorName).addHandlerForOperation(.\(internalName), httpMethod: .\(httpMethod),
                            operation: handle\(name.startingWithUppercase),
                            allowedErrors: allowedErrorsFor\(name.startingWithUppercase),
                            transformMiddleware: \(transformMiddleware)(statusOnSuccess: .ok))
                        """)
                }
            } else {
                switch operationStubGeneration {
                case .functionWithinContext:
                    fileBuilder.appendLine("""
                        \(selectorName).addHandlerForOperationProvider(
                            .\(internalName), httpMethod: .\(httpMethod),
                            operationProvider: \(baseName)OperationsContext.handle\(name.startingWithUppercase),
                            allowedErrors: allowedErrorsFor\(name.startingWithUppercase))
                        """)
                case .standaloneFunction:
                    fileBuilder.appendLine("""
                        \(selectorName).addHandlerForOperation(.\(internalName), httpMethod: .\(httpMethod),
                            operation: handle\(name.startingWithUppercase),
                            allowedErrors: allowedErrorsFor\(name.startingWithUppercase))
                        """)
                }
            }
        }
    }
}
