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
//  ServiceModelCodeGenerator+generateOperationsContextGenerator.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator {
    /**
     Generate the stub operations context generator for the generated application.
     */
    func generateOperationsContextGenerator(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = "\(baseName)OperationsContextGenerator.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)OperationsHTTP1"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            // \(baseName)OperationsContextGenerator.swift
            // \(baseName)OperationsHTTP1
            //
            
            import Foundation
            import \(baseName)Operations
            import SmokeOperations
            import SmokeOperationsHTTP1Server
            import Logging
            
            /**
             Per-invocation generator for the context to be passed to each of the \(baseName) operations.
             */
            public struct \(baseName)OperationsContextGenerator {
                // TODO: Add properties to be accessed by the operation handlers
            
                public init() {
                }
            
                public func get(invocationReporting: SmokeServerInvocationReporting<SmokeInvocationTraceContext>) -> \(baseName)OperationsContext {
                    return \(baseName)OperationsContext(logger: invocationReporting.logger)
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
}
