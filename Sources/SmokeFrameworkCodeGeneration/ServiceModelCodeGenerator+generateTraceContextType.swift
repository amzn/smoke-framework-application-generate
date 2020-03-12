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
//  ServiceModelCodeGenerator+generateTraceContextType.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

extension ServiceModelCodeGenerator {
    /**
     Generate the hander selector for the operation handlers for the generated application.
     */
    func generateTraceContextType(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = "\(baseName)OperationDelegate.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        // build a map of http url to operation handler
        fileBuilder.appendLine("""
            // swiftlint:disable superfluous_disable_command
            // swiftlint:disable file_length line_length identifier_name type_name vertical_parameter_alignment
            // -- Generated Code; do not edit --
            //
            // \(baseName)OperationDelegate.swift
            // \(baseName)OperationsHTTP1
            //
            
            import Foundation
            import SmokeOperationsHTTP1
            
            /**
             Customizing this typealias allows an application to affect how the SmokeFramework handles incoming
             operations.
             */
            public typealias \(baseName)OperationDelegate = JSONPayloadHTTP1OperationDelegate<SmokeInvocationTraceContext>
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
}
