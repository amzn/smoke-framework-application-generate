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
//  ServiceModelCodeGenerator+generateServerOperationStubs.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

extension ServiceModelCodeGenerator {
    /**
     Generate the stub operations handlers for the generated application.
     */
    func generateServerOperationHandlerStubs(generationType: GenerationType, operationStubGenerationRule: OperationStubGenerationRule,
                                             asyncOperationStubs: CodeGenFeatureStatus) {
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        let filePath = "\(baseFilePath)/Sources/\(baseName)Operations"
        
        // for each of the operations
        for (operationName, operationDescription) in model.operationDescriptions {
            let name = operationName.startingWithUppercase
            let fileBuilder = FileBuilder()
            
            let fileName = "\(name).swift"
            
            if case .serverUpdate = generationType {
                guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                    continue
                }
            }
            
            fileBuilder.appendLine("""
                //
                // \(name).swift
                // \(baseName)Operations
                //
                
                import Foundation
                import \(baseName)Model
                
                /**
                 Handler for the \(name) operation.
                """)
            
            // if there is input
            let input = getOperationInputAndAddDescription(
                operationDescription: operationDescription,
                baseName: baseName, fileBuilder: fileBuilder)
            
            // if there is output
            let (output, functionOutputType) = getOperationOutputAndAddDescription(
                operationDescription: operationDescription,
                baseName: baseName, fileBuilder: fileBuilder)
            
            // if there can be errors
            let errors = getOperationErrorsAndAddDescription(
                operationDescription: operationDescription, fileBuilder: fileBuilder)
            
            fileBuilder.appendLine(" */")
            
            let asyncInfix: String
            switch asyncOperationStubs {
            case .disabled:
                asyncInfix = ""
            case .enabled:
                asyncInfix = " async"
            }
            
            let operationStubGeneration = operationStubGenerationRule.getStubGeneration(forOperation: operationName)
            
            switch operationStubGeneration {
            case .functionWithinContext:
                if let output = output {
                    fileBuilder.appendLine("""
                        extension \(baseName)OperationsContext {
                            public func handle\(name)(\(input))\(asyncInfix)\(errors)
                            \(output) {
                        """)
                } else {
                    fileBuilder.appendLine("""
                        extension \(baseName)OperationsContext {
                            public func handle\(name)(\(input))\(asyncInfix)\(errors) {
                        """)
                }
                
                fileBuilder.incIndent()
            case .standaloneFunction:
                if let output = output {
                    fileBuilder.appendLine("""
                        public func handle\(name)(\(input),
                                context: \(baseName)OperationsContext)\(asyncInfix)\(errors) \(output) {
                        """)
                } else {
                    fileBuilder.appendLine("""
                        public func handle\(name)(\(input),
                                context: \(baseName)OperationsContext)\(asyncInfix)\(errors) {
                        """)
                }
            }
            fileBuilder.incIndent()
            
            // return a default instance of the output type
            if let outputType = functionOutputType {
                let outputTypeName = outputType.getNormalizedTypeName(forModel: model)
                
                fileBuilder.appendLine("return \(outputTypeName).__default")
            }
            
            fileBuilder.appendLine("}", preDec: true)
            
            if case .functionWithinContext = operationStubGeneration {
                fileBuilder.appendLine("}", preDec: true)
            }
            
            fileBuilder.write(toFile: fileName, atFilePath: filePath)
        }
    }
    
    private func getOperationInputAndAddDescription(
            operationDescription: OperationDescription,
            baseName: String,
            fileBuilder: FileBuilder) -> String {
        let input: String
        if let inputType = operationDescription.input {
            let type = inputType.getNormalizedTypeName(forModel: model)
            input = "input: \(baseName)Model.\(type)"
            
            fileBuilder.appendEmptyLine()
            fileBuilder.appendLine(" - Parameters:")
            fileBuilder.appendLine("     - input: The validated \(type) object being passed to this operation.")
            fileBuilder.appendLine("     - context: The context provided for this operation.")
        } else {
            input = ""
        }
        
        return input
    }
    
    private func getOperationOutputAndAddDescription(
            operationDescription: OperationDescription,
            baseName: String,
            fileBuilder: FileBuilder) -> (output: String?, functionOutputType: String?) {
        let output: String?
        let functionOutputType: String?
        if let outputType = operationDescription.output {
            let type = outputType.getNormalizedTypeName(forModel: model)
            output = "-> \(baseName)Model.\(type)"
            let description = " - Returns: The \(type) object to be passed back from the caller of this operation."
            
            fileBuilder.appendLine(description)
            fileBuilder.appendLine("     Will be validated before being returned to caller.")
            functionOutputType = type
        } else {
            output = nil
            functionOutputType = nil
        }
        
        return (output: output, functionOutputType: functionOutputType)
    }
    
    private func getOperationErrorsAndAddDescription(
            operationDescription: OperationDescription,
            fileBuilder: FileBuilder) -> String {
        let errors: String
        if !operationDescription.errors.isEmpty {
            errors = " throws"
            var description = " - Throws: "
            
            let sortedErrors = operationDescription.errors.sorted(by: <)
            
            for (index, error) in sortedErrors.enumerated() {
                if index != 0 {
                    description += ", "
                }
                description += error.type.normalizedErrorName
            }
            description += "."
            fileBuilder.appendLine(description)
        } else {
            errors = ""
        }
        
        return errors
    }
}
