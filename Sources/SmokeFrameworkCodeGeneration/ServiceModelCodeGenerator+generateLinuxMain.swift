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
//  ServiceModelCodeGenerator+generateLinuxMain.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration

extension ServiceModelCodeGenerator {

    func generateLinuxMain() {
        
        let fileBuilder = FileBuilder()
        let baseName = applicationDescription.baseName
        let baseFilePath = applicationDescription.baseFilePath
        
        fileBuilder.appendLine("""
            //
            // LinuxMain.swift
            //
            
            import XCTest
            @testable import \(baseName)OperationsTests
            
            XCTMain([
            """)
        
        let operations = [String](model.operationDescriptions.keys)
        
        fileBuilder.incIndent()
        for operationName in operations.sorted(by: <) {
            let name = operationName.startingWithUppercase
            fileBuilder.appendLine("testCase(\(name)Tests.allTests),")
        }
        fileBuilder.appendLine("])", preDec: true)
        
        let fileName = "LinuxMain.swift"
        fileBuilder.write(toFile: fileName, atFilePath: "\(baseFilePath)/Tests")
    }
}
