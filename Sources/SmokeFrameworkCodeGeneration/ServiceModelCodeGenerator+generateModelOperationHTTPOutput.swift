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
//  ServiceModelCodeGenerator+generateModelOperationHTTPOutput.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

public extension ServiceModelCodeGenerator {
    
    /**
     Generate HTTP output for each operation.
     */
    func generateModelOperationHTTPOutput() {
        let baseName = applicationDescription.baseName
        
        let fileBuilder = FileBuilder()
        
        if let fileHeader = customizations.fileHeader {
            fileBuilder.appendLine(fileHeader)
        }
        
        addGeneratedFileHeader(fileBuilder: fileBuilder)
        
        fileBuilder.appendLine("""
            // \(baseName)OperationsHTTPOutput.swift
            // \(baseName)OperationsHTTP1
            //
            
            import Foundation
            import SmokeOperationsHTTP1
            import \(baseName)Model
            
            """)
        
        if case let .external(libraryImport: libraryImport, _) = customizations.validationErrorDeclaration {
            fileBuilder.appendLine("import \(libraryImport)")
        }
        
        let sortedOperations = model.operationDescriptions.sorted { (left, right) in left.key < right.key }
        
        var alreadySeenTypes: Set<String> = []
        sortedOperations.forEach { operation in
            addOperationHTTPOutput(operation: operation.key,
                                   operationDescription: operation.value,
                                   alreadySeenTypes: &alreadySeenTypes,
                                   fileBuilder: fileBuilder)
        }
        
        let fileName = "\(baseName)OperationsHTTPOutput.swift"
        let baseFilePath = applicationDescription.baseFilePath
        fileBuilder.write(toFile: fileName, atFilePath: "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1")
    }
}
