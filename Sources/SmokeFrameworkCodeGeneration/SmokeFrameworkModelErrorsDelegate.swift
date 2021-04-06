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
                                             errorTypes: [ErrorType]) {
        // nothing to do
    }
    
    func errorTypeAdditionalErrorIdentitiesGenerator(fileBuilder: FileBuilder,
                                                     errorTypes: [ErrorType]) {
         fileBuilder.appendLine("""
         private let __validationErrorIdentity = "ValidationError"
         private let __unrecognizedErrorIdentity = "UnrecognizedError"
         private let __unknownErrorIdentity = "UnknownError"
         """)
    }
    
    func errorTypeWillAddAdditionalCases(fileBuilder: FileBuilder,
                                         errorTypes: [ErrorType]) -> Int {
        return 3
    }
    
    func errorTypeAdditionalErrorCasesGenerator(fileBuilder: FileBuilder,
                                                errorTypes: [ErrorType]) {
        fileBuilder.appendLine("""
        case validationError(reason: String)
        case unrecognizedError(String, String?)
        case unknownError
        """)
    }
    
    func errorTypeCodingKeysGenerator(fileBuilder: FileBuilder,
                                      errorTypes: [ErrorType]) {
        fileBuilder.appendLine("""
        enum CodingKeys: String, CodingKey {
            case type = "__type"
            case unrecognizedType = "__unrecognizedType"
            case errorMessage = "message"
        }
        """)
    }
    
    func errorTypeIdentityGenerator(fileBuilder: FileBuilder,
                                    codingErrorUnknownError: String) -> String {
        fileBuilder.appendLine("""
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let type = try values.decodeIfPresent(String.self, forKey: .type)
            let errorMessage = try values.decodeIfPresent(String.self, forKey: .errorMessage)

            guard let errorReason = type else {
                throw \(codingErrorUnknownError)
            }
            """)
        
            return "errorReason"
    }
    
    func errorTypeAdditionalErrorDecodeStatementsGenerator(fileBuilder: FileBuilder,
                                                           errorTypes: [ErrorType]) {
        // nothing to do
    }
    
    func errorTypeAdditionalErrorEncodeStatementsGenerator(fileBuilder: FileBuilder,
                                                           errorTypes: [ErrorType]) {
        fileBuilder.appendLine("""
            case .validationError(reason: let reason):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(reason, forKey: .errorMessage)
            case .unrecognizedError(let errorReason, let errorMessage):
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(errorReason, forKey: .unrecognizedType)
                try container.encode(errorMessage, forKey: .errorMessage)
            case .unknownError:
                break
            """)
    }
    
    func errorTypeAdditionalDescriptionCases(fileBuilder: FileBuilder,
                                             errorTypes: [ErrorType]) {
        fileBuilder.appendLine("""
            case .validationError:
                return __validationErrorIdentity
            case .unrecognizedError:
                return __unrecognizedErrorIdentity
            case .unknownError:
                return __unknownErrorIdentity
            """)
    }
}
