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
//  SmokeFrameworkModelErrorsDelegate.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

struct SmokeFrameworkModelErrorsDelegate: ModelErrorsDelegate {
    let optionSetGeneration: ErrorOptionSetGeneration =
        .generateWithCustomConformance(libraryImport: "SmokeOperations", conformanceType: "ErrorIdentifiableByDescription")
    let generateEncodableConformance: Bool = true
    let generateCustomStringConvertibleConformance: Bool = true
    let canExpectValidationError: Bool = true
    
    func errorTypeAdditionalImportsGenerator(fileBuilder: FileBuilder,
                                             errorTypes: [String]) {
        // nothing to do
    }
    
    func errorTypeAdditionalErrorIdentitiesGenerator(fileBuilder: FileBuilder, errorTypes: [String]) {
        // nothing to do
    }
    
    func errorTypeWillAddAdditionalCases(fileBuilder: FileBuilder, errorTypes: [String]) -> Int {
        return 0
    }
    
    func errorTypeAdditionalErrorCasesGenerator(fileBuilder: FileBuilder,
                                                errorTypes: [String]) {
        // nothing to do
    }
    
    func errorTypeCodingKeysGenerator(fileBuilder: FileBuilder,
                                      errorTypes: [String]) {
        fileBuilder.appendLine("""
        enum CodingKeys: String, CodingKey {
            case type = "__type"
            case errorMessage = "message"
        }
        """)
    }
    
    func errorTypeIdentityGenerator(fileBuilder: FileBuilder) -> String {
        fileBuilder.appendLine("""
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let type = try values.decodeIfPresent(String.self, forKey: .type) ?? ""
            let errorMessage = try values.decodeIfPresent(String.self, forKey: .errorMessage)
            """)
        
            return "type"
    }
    
    func errorTypeAdditionalErrorDecodeStatementsGenerator(fileBuilder: FileBuilder,
                                                           errorTypes: [String]) {
        // nothing to do
    }
}
