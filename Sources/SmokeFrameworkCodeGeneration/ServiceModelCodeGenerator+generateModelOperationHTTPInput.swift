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
//  ServiceModelCodeGenerator+generateModelOperationHTTPInput.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

public extension ServiceModelCodeGenerator where TargetSupportType: ModelTargetSupport & HTTP1IntegrationTargetSupport {
    /**
     Generate HTTP input for each operation.
     */
    func generateModelOperationHTTPInput() {
        let baseName = applicationDescription.baseName
        let modelTargetName = self.targetSupport.modelTargetName
        let http1IntegrationTargetName = self.targetSupport.http1IntegrationTargetName
        
        let fileBuilder = FileBuilder()
        
        if let fileHeader = customizations.fileHeader {
            fileBuilder.appendLine(fileHeader)
        }
        
        addGeneratedFileHeader(fileBuilder: fileBuilder)
        
        fileBuilder.appendLine("""
            // \(baseName)OperationsHTTPInput.swift
            // \(http1IntegrationTargetName)
            //
            
            import Foundation
            import SmokeOperationsHTTP1
            import \(modelTargetName)
            """)
        
        if case let .external(libraryImport: libraryImport, _) = customizations.validationErrorDeclaration {
            fileBuilder.appendLine("import \(libraryImport)")
        }
        
        let sortedOperations = model.operationDescriptions.sorted { (left, right) in left.key < right.key }
        
        var alreadyEmittedTypes: [String: OperationInputDescription] = [:]
        sortedOperations.forEach { operation in
            addOperationHTTPInput(operation: operation.key,
                                  operationDescription: operation.value,
                                  fileBuilder: fileBuilder,
                                  alreadyEmittedTypes: &alreadyEmittedTypes)
        }
        
        let fileName = "\(baseName)OperationsHTTPInput.swift"
        let baseFilePath = applicationDescription.baseFilePath
        fileBuilder.write(toFile: fileName, atFilePath: "\(baseFilePath)/Sources/\(http1IntegrationTargetName)")
    }
}
