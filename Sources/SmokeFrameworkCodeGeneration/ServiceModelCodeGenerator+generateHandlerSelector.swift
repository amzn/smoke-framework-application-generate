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
    func generateServerHanderSelector() {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        // build a map of http url to operation handler
        fileBuilder.appendLine("""
            // swiftlint:disable superfluous_disable_command
            // swiftlint:disable file_length line_length identifier_name type_name vertical_parameter_alignment
            // -- Generated Code; do not edit --
            //
            // \(baseName)OperationsHanderSelector.swift
            // \(baseName)OperationsHTTP1
            //
            
            import Foundation
            import SmokeOperationsHTTP1
            import SmokeOperationsHTTP1Server
            import \(baseName)Model
            import \(baseName)Operations
            import SmokeOperations
            
            """)
        
        fileBuilder.appendLine("""
            extension \(baseName)ModelOperations: OperationIdentity {}
            
            public typealias HandlerSelectorType =
                StandardSmokeHTTP1HandlerSelector<\(baseName)OperationsContext, \(baseName)OperationDelegate,
                                                  \(baseName)ModelOperations>
            
            public func createHandlerSelector() -> HandlerSelectorType {
            """)
        
        fileBuilder.incIndent()
        
        if model.operationDescriptions.isEmpty {
            fileBuilder.appendLine("""
                return HandlerSelectorType()
                """)
        } else {
            fileBuilder.appendLine("""
                var newHandler = HandlerSelectorType(defaultOperationDelegate: JSONPayloadHTTP1OperationDelegate())
                """)
        }
        
        // sort the operations in alphabetical order for output
        let sortedOperations = model.operationDescriptions.sorted { entry1, entry2 in
            return entry1.key < entry2.key
        }
        
        // iterate through the operations
        for entry in sortedOperations {
            generateHandlerForOperation(name: entry.key, operationDescription: entry.value, baseName: baseName, fileBuilder: fileBuilder)
        }
        
        if !model.operationDescriptions.isEmpty {
            fileBuilder.appendLine("""
                return newHandler
                """)
        }
        
        fileBuilder.decIndent()
        fileBuilder.appendLine("}")
        
        let fileName = "\(baseName)OperationsHanderSelector.swift"
        fileBuilder.write(toFile: fileName, atFilePath: "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1")
    }
    
    private func generateHandlerForOperation(name: String, operationDescription: OperationDescription,
                                             baseName: String, fileBuilder: FileBuilder) {
        if let httpMethod = operationDescription.httpVerb {
            let sortedErrors = operationDescription.errors.sorted { entry1, entry2 in
                return entry1.code < entry2.code
            }
            
            var allowedErrors = ""
            for (index, error) in sortedErrors.enumerated() {
                let errorName = error.type.normalizedErrorName
                
                if index == 0 {
                    allowedErrors += "(\(baseName)ErrorTypes.\(errorName), \(error.code))"
                } else {
                    allowedErrors += ", (\(baseName)ErrorTypes.\(errorName), \(error.code))"
                }
            }
            
            let operationFunctionName = "handle\(name.startingWithUppercase)"
            let internalName = name.upperToLowerCamelCase
            
            fileBuilder.appendLine("""
                
                newHandler.addHandlerForOperation(.\(internalName), httpMethod: .\(httpMethod),
                                                  operation: \(operationFunctionName),
                                                  allowedErrors: [\(allowedErrors)])
                """)
        }
    }
}
