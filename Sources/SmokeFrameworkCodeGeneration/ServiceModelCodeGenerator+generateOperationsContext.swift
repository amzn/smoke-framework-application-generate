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
//  ServiceModelCodeGenerator+generateOperationsContext.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator {
    /**
     Generate the stub operations context for the generated application.
     */
    func generateOperationsContext(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = "\(baseName)OperationsContext.swift"
        let filePath = "\(baseFilePath)/Sources/\(baseName)Operations"
        
        if generationType.isUpdate {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        var conformingProtocols: [String] = []
        var conformancePadding: String = ""
        if case .enabled = self.customizations.addSendableConformance {
            conformingProtocols.append("Sendable")
            conformancePadding = " "
        }
        
        let conformingProtocolsString = conformingProtocols.joined(separator: ", ")
        
        fileBuilder.appendLine("""
            //
            // \(baseName)OperationsContext.swift
            // \(baseName)Operations
            //
            
            import Foundation
            import Logging
            
            /**
             The context to be passed to each of the \(baseName) operations.
             */
            public struct \(baseName)OperationsContext \(conformingProtocolsString)\(conformancePadding){
                let logger: Logger
                // TODO: Add properties to be accessed by the operation handlers
            
                public init(logger: Logger) {
                    self.logger = logger
                }
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
}
