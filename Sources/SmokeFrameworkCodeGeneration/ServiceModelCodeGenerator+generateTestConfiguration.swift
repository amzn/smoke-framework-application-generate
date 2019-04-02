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
//  ServiceModelCodeGenerator+generateTestConfiguration.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator {

    func generateTestConfiguration(generationType: GenerationType) {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        let fileName = "\(baseName)TestConfiguration.swift"
        let filePath = "\(baseFilePath)/Tests/\(baseName)OperationsTests"
        
        if case .serverUpdate = generationType {
            guard !FileManager.default.fileExists(atPath: "\(filePath)/\(fileName)") else {
                return
            }
        }
        
        fileBuilder.appendLine("""
            //
            // \(baseName)TestConfiguration.swift
            // \(baseName)OperationsTests
            //
            
            import XCTest
            @testable import \(baseName)Operations
            import \(baseName)Model
            
            func createOperationsContext() -> \(baseName)OperationsContext {
                return \(baseName)OperationsContext()
            }
            """)
        
        fileBuilder.write(toFile: fileName, atFilePath: filePath)
    }
}
