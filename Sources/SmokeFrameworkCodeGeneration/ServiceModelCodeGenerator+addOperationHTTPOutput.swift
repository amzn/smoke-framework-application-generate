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
//  ServiceModelCodeGenerator+addOperationHTTPOutput.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

public extension ServiceModelCodeGenerator {
    private struct HTTPRequestOutputTypes {
        let bodyTypeName: String
        let bodyTypeConversion: String
        let additionalHeadersTypeName: String
        let additionalHeadersTypeConversion: String
    }
    
    func addOperationHTTPOutput(operation: String,
                                operationDescription: OperationDescription,
                                alreadySeenTypes: inout Set<String>,
                                fileBuilder: FileBuilder) {
        
        let name = operation.getNormalizedTypeName(forModel: model)
        let baseName = applicationDescription.baseName
        
        guard let outputType = operationDescription.output else {
            // nothing to be done
            return
        }
        guard let structureDefinition = model.structureDescriptions[outputType] else {
            fatalError("No structure with type \(outputType)")
        }
        
        let outputDescription: OperationOutputDescription
        if let override = modelOverride?.operationOutputOverrides?[name] {
            outputDescription = override
        } else {
            outputDescription = operationDescription.outputDescription
        }
        
        let outputTypeName = outputType.getNormalizedTypeName(forModel: model)
        let operationPrefix = "\(name)OperationOutput"
        
        guard !alreadySeenTypes.contains(outputTypeName) else {
            return
        }
        alreadySeenTypes.insert(outputTypeName)
        
        addOperationHTTPRequestOutput(
            structureDefinition: structureDefinition,
            outputDescription: outputDescription,
            outputType: outputType,
            outputTypeName: outputTypeName,
            operationPrefix: operationPrefix,
            name: name,
            fileBuilder: fileBuilder,
            baseName: baseName)
    }
    
    private func addBodyOperationHTTPOutput(bodyMembers: [String: Member],
                                            additionalHeadersMembers: [String: Member],
                                            outputTypeName: String,
                                            operationPrefix: String)
        -> (bodyTypeName: String, bodyTypeConversion: String) {
            let bodyTypeName: String
            let bodyTypeConversion: String
            let baseName = applicationDescription.baseName
            if !bodyMembers.isEmpty {
                if additionalHeadersMembers.isEmpty {
                    bodyTypeName = outputTypeName
                    bodyTypeConversion = "self"
                } else {
                    bodyTypeName = "\(operationPrefix)Body"
                    bodyTypeConversion = "as\(baseName)Model\(operationPrefix)Body()"
                }
            } else {
                bodyTypeName = "String"
                bodyTypeConversion = "nil"
            }
            
            return (bodyTypeName: bodyTypeName, bodyTypeConversion: bodyTypeConversion)
    }
    
    private func addAdditionalHeadersOperationHTTPOutput(additionalHeadersMembers: [String: Member],
                                                         operationPrefix: String)
        -> (additionalHeadersTypeName: String, additionalHeadersTypeConversion: String) {
            let additionalHeadersTypeName: String
            let additionalHeadersTypeConversion: String
            let baseName = applicationDescription.baseName
            if !additionalHeadersMembers.isEmpty {
                additionalHeadersTypeName = "\(operationPrefix)Headers"
                additionalHeadersTypeConversion = "as\(baseName)Model\(operationPrefix)Headers()"
            } else {
                additionalHeadersTypeName = "String"
                additionalHeadersTypeConversion = "nil"
            }
            
            return (additionalHeadersTypeName: additionalHeadersTypeName,
                    additionalHeadersTypeConversion: additionalHeadersTypeConversion)
    }
    
    private func addAsMember(fieldName: String, members: inout [String: Member],
                             unassignedMembers: inout [String: Member]) {
        if let member = unassignedMembers[fieldName] {
            members[fieldName] = member
            unassignedMembers[fieldName] = nil
        }
    }
    
    private func addRequestOutputStructure(fileBuilder: FileBuilder, name: String,
                                           outputTypeName: String,
                                           httpRequestOutputTypes: HTTPRequestOutputTypes) {
        fileBuilder.appendLine("""
            /**
             Type to handle the http output to the \(name) operation.
             */
            extension \(outputTypeName): OperationHTTP1OutputProtocol {
                public var bodyEncodable: \(httpRequestOutputTypes.bodyTypeName)? {
                    return \(httpRequestOutputTypes.bodyTypeConversion)
                }
                public var additionalHeadersEncodable: \(httpRequestOutputTypes.additionalHeadersTypeName)? {
                    return \(httpRequestOutputTypes.additionalHeadersTypeConversion)
                }
            }
            """)
    }
    
    private func addOperationHTTPRequestOutput(structureDefinition: StructureDescription,
                                               outputDescription: OperationOutputDescription,
                                               outputType: String,
                                               outputTypeName: String,
                                               operationPrefix: String,
                                               name: String,
                                               fileBuilder: FileBuilder,
                                               baseName: String) {
        var unassignedMembers = structureDefinition.members
        var bodyMembers: [String: Member] = [:]
        var headersMembers: [String: Member] = [:]
        
        outputDescription.bodyFields.forEach {
            addAsMember(fieldName: $0, members: &bodyMembers,
                        unassignedMembers: &unassignedMembers)
        }
        outputDescription.headerFields.forEach {
            addAsMember(fieldName: $0, members: &headersMembers,
                        unassignedMembers: &unassignedMembers)
        }
        
        bodyMembers.merge(unassignedMembers) { (old, _) in old }
        
        let bodyTypeName: String
        let bodyTypeConversion: String
        
        if let payloadAsMember = outputDescription.payloadAsMember {
            guard let payloadMember = structureDefinition.members[payloadAsMember] else {
                fatalError("Unknown payload member.")
            }
            
            let parameterName = getNormalizedVariableName(
                modelTypeName: payloadAsMember,
                inStructure: name,
                reservedWordsAllowed: true)
            
            bodyTypeName = payloadMember.value.getNormalizedTypeName(forModel: model)
            bodyTypeConversion = "\(parameterName)"
        } else {
            (bodyTypeName, bodyTypeConversion) = addBodyOperationHTTPOutput(
                bodyMembers: bodyMembers,
                additionalHeadersMembers: headersMembers,
                outputTypeName: outputTypeName,
                operationPrefix: operationPrefix)
        }
        
        let (additionalHeadersTypeName, additionalHeadersTypeConversion) = addAdditionalHeadersOperationHTTPOutput(
            additionalHeadersMembers: headersMembers, operationPrefix: operationPrefix)
        
        let httpRequestOutputTypes = HTTPRequestOutputTypes(
            bodyTypeName: bodyTypeName, bodyTypeConversion: bodyTypeConversion,
            additionalHeadersTypeName: additionalHeadersTypeName,
            additionalHeadersTypeConversion: additionalHeadersTypeConversion)
        
        addRequestOutputStructure(fileBuilder: fileBuilder, name: name,
                                  outputTypeName: outputTypeName,
                                  httpRequestOutputTypes: httpRequestOutputTypes)
    }
    
    func createConversionFunction(originalTypeName: String,
                                  derivedTypeName: String,
                                  members: [String: Member],
                                  fileBuilder: FileBuilder) {
        let baseName = applicationDescription.baseName
        let postfix: String
        if members.isEmpty {
            postfix = ")"
        } else {
            postfix = ""
        }
        
        fileBuilder.appendLine("""
            public extension \(originalTypeName) {
                public func as\(baseName)Model\(derivedTypeName)() -> \(derivedTypeName) {
                    return \(derivedTypeName)(\(postfix)
            """)
        
        // get a sorted list of the required members of the structure
        let sortedMembers = members.sorted { entry1, entry2 in
            return entry1.value.position < entry2.value.position
        }
        
        fileBuilder.incIndent()
        fileBuilder.incIndent()
        fileBuilder.incIndent()
        sortedMembers.enumerated().forEach { details in
            let variableName = getNormalizedVariableName(modelTypeName: details.element.key)
            
            let postfix: String
            if details.offset == members.count - 1 {
                postfix = ")"
            } else {
                postfix = ","
            }
            fileBuilder.appendLine("\(variableName): \(variableName)\(postfix)")
        }
        
        fileBuilder.decIndent()
        fileBuilder.decIndent()
        fileBuilder.decIndent()
        fileBuilder.appendLine("""
                }
            }
            """)
    }
}
