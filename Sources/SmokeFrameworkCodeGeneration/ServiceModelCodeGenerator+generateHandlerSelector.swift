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
import SwiftSyntax
import SwiftSyntaxBuilder

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
        
        let source = SourceFile {
            Comments { getGeneratedFileHeader(baseName: baseName) }
            EmptyLine()
            Import("Foundation")
            Import("\(baseName)Model")
            Import("\(baseName)Operations")
            Import("SmokeOperations")
            Import("SmokeOperationsHTTP1")
            
            if case .enabled = eventLoopFutureOperationHandlers {
                Import("SmokeAsyncHTTP1")
            }
            
            EmptyLine()
            Extension("\(baseName)ModelOperations").Inherits("OperationIdentity")
            
            EmptyLine()
            Public.Extension("\(baseName)ModelOperations") {
                Static.Function("addToSmokeServer").GenericFor("SelectorType", extending: "SmokeHTTP1HandlerSelector")
                    .Input("selector", whichIsA: Inout("SelectorType"))
                    .Where("SelectorType.ContextType", isSameAs: "PlaybackObjectsOperationsContext")
                    .Where("SelectorType.OperationIdentifer", isSameAs: "PlaybackObjectsModelOperations") {
                        // sort the operations in alphabetical order for output
                        let sortedOperations = model.operationDescriptions.sorted { entry1, entry2 in
                            return entry1.key < entry2.key
                        }
                        
                        // iterate through the operations
                        for entry in sortedOperations {
                            generateHandlerForOperationBuilder(
                                name: entry.key, operationDescription: entry.value, baseName: baseName,
                                fileBuilder: fileBuilder, operationStubGenerationRule: operationStubGenerationRule)
                        }
                    }
            }
        }
        
        
        
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
        source.write(toFile: fileName, atFilePath: "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1")
    }
    
    @CodeBlockItemListBuilder
    private func generateHandlerForOperationBuilder(name: String, operationDescription: OperationDescription,
                                                    baseName: String, fileBuilder: FileBuilder,
                                                    operationStubGenerationRule: OperationStubGenerationRule) -> ExpressibleAsCodeBlockItemList {
        
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

@TriviaListBuilder func getGeneratedFileHeader(baseName: String) -> ExpressibleAsTriviaPieceList {
    TriviaPiece.docLineComment("""
        // swiftlint:disable superfluous_disable_command
        // swiftlint:disable file_length line_length identifier_name type_name vertical_parameter_alignment
        // swiftlint:disable type_body_length function_body_length generic_type_name cyclomatic_complexity
        // -- Generated Code; do not edit --
        //
        // \(baseName)OperationsHanderSelector.swift
        // \(baseName)OperationsHTTP1
        //
        """)
}

extension SourceFile {
    func write(toFile fileName: String, atFilePath filePath: String) {
        let syntax = self.buildSyntax(format: Format())
        
        var text = ""
        syntax.write(to: &text)
        
        let fileManager = FileManager.default
        
        do {
            // create any directories as needed
            try fileManager.createDirectory(atPath: filePath,
                                            withIntermediateDirectories: true, attributes: nil)
            
            // Write contents to file
            try text.write(toFile: filePath + "/" + fileName, atomically: false, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
        }
    }
}
