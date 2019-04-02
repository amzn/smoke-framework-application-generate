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
//  ServiceModelCodeGenerator+addOperationHTTPInput.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

public extension ServiceModelCodeGenerator {
    func addOperationHTTPInput(operation: String,
                               operationDescription: OperationDescription,
                               fileBuilder: FileBuilder,
                               alreadyEmittedTypes: inout [String: OperationInputDescription]) {
        
        let name = operation.getNormalizedTypeName(forModel: model)
        let baseName = applicationDescription.baseName
        
        guard let inputType = operationDescription.input else {
            // nothing to be done
            return
        }
        guard let structureDefinition = model.structureDescriptions[inputType] else {
            fatalError("No structure with type \(inputType)")
        }
        
        let inputDescription: OperationInputDescription
        if let override = modelOverride?.operationInputOverrides?[name] {
            inputDescription = override
        } else {
            inputDescription = operationDescription.inputDescription
        }
        
        let inputTypeName = inputType.getNormalizedTypeName(forModel: model)
        let operationPrefix = "\(name)OperationInput"
        
        if let previousOperation = alreadyEmittedTypes[inputTypeName] {
            if previousOperation != inputDescription {
                fatalError("Incompatible duplicate operation inputs for \(inputTypeName)")
            }
            
            return
        }
        alreadyEmittedTypes[inputTypeName] = inputDescription
        
        addOperationHTTPResponseInput(
            structureDefinition: structureDefinition,
            inputDescription: inputDescription,
            inputType: inputType,
            inputTypeName: inputTypeName,
            operationPrefix: operationPrefix,
            name: name,
            fileBuilder: fileBuilder,
            baseName: baseName)
    }
    
    private struct HTTPResponseInputTypes {
        let bodyTypeName: String?
        let headersTypeName: String?
        let queryTypeName: String?
        let pathTypeName: String?
        let membersLocation: [String: LocationInput]
        let payloadAsMember: String?
    }
    
    private func addPathOperationHTTPResponseInput(hasPathMembers: Bool,
                                                   operationPrefix: String) -> String? {
        let pathTypeName: String?
        if hasPathMembers {
            pathTypeName = "\(operationPrefix)Path"
        } else {
            pathTypeName = nil
        }
        
        return pathTypeName
    }
    
    private func addQueryOperationHTTPResponseInput(hasQueryMembers: Bool,
                                                    operationPrefix: String) -> String? {
        let queryTypeName: String?
        if hasQueryMembers {
            queryTypeName = "\(operationPrefix)Query"
        } else {
            queryTypeName = nil
        }
        
        return queryTypeName
    }
    
    private func addBodyOperationHTTPResponseInput(hasBodyMembers: Bool,
                                                   operationPrefix: String) -> String? {
        let bodyTypeName: String?
        if hasBodyMembers {
            bodyTypeName = "\(operationPrefix)Body"
        } else {
            bodyTypeName = nil
        }
        
        return bodyTypeName
    }
    
    private func addHeadersOperationHTTPResponseInput(hasHeadersMembers: Bool,
                                                      operationPrefix: String) -> String? {
        let headersTypeName: String?
        if hasHeadersMembers {
            headersTypeName = "\(operationPrefix)AdditionalHeaders"
        } else {
            headersTypeName = nil
        }
            
        return headersTypeName
    }
    
    private func addAsMember(fieldName: String, members: inout [String: Member],
                             unassignedMembers: inout [String: Member]) {
        if let member = unassignedMembers[fieldName] {
            members[fieldName] = member
            unassignedMembers[fieldName] = nil
        }
    }
    
    private func addResponseInputStructure(fileBuilder: FileBuilder,
                                           name: String, inputTypeName: String,
                                           httpResponseInputTypes: HTTPResponseInputTypes) {
        fileBuilder.appendLine("""
            
            /**
             Type to handle the http input to the \(name) operation.
             */
            extension \(inputTypeName): OperationHTTP1InputProtocol {
                public typealias QueryType = \(httpResponseInputTypes.queryTypeName ?? "String")
                public typealias PathType = \(httpResponseInputTypes.pathTypeName ?? "String")
                public typealias BodyType = \(httpResponseInputTypes.bodyTypeName ?? "String")
                public typealias HeadersType = \(httpResponseInputTypes.headersTypeName ?? "String")
            
                public static func compose(queryDecodableProvider: () throws -> QueryType,
                                           pathDecodableProvider: () throws -> PathType,
                                           bodyDecodableProvider: () throws -> BodyType,
                                           headersDecodableProvider: () throws -> HeadersType) throws -> \(inputTypeName) {
            """)
        
        if httpResponseInputTypes.queryTypeName != nil {
            fileBuilder.appendLine("""
                        let query = try queryDecodableProvider()
                """)
        }
        if httpResponseInputTypes.pathTypeName != nil {
            fileBuilder.appendLine("""
                        let path = try pathDecodableProvider()
                """)
        }
        if httpResponseInputTypes.bodyTypeName != nil {
            fileBuilder.appendLine("""
                        let body = try bodyDecodableProvider()
                """)
        }
        if httpResponseInputTypes.headersTypeName != nil {
            fileBuilder.appendLine("""
                        let headers = try headersDecodableProvider()
                """)
        }
        fileBuilder.appendEmptyLine()
        
        fileBuilder.incIndent()
        fileBuilder.incIndent()
        createInputStructureStubVariable(type: inputTypeName,
                                         fileBuilder: fileBuilder,
                                         declarationPrefix: "return",
                                         memberLocation: httpResponseInputTypes.membersLocation,
                                         payloadAsMember: httpResponseInputTypes.payloadAsMember)
        fileBuilder.decIndent()
        fileBuilder.decIndent()
        
        fileBuilder.appendLine("""
                }
            }
            """)
    }
    
    private func getBodyTypeName(inputDescription: OperationInputDescription,
                                 structureDefinition: StructureDescription,
                                 hasBodyMembers: Bool,
                                 operationPrefix: String) -> String? {
        let bodyTypeName: String?
        if let payloadAsMember = inputDescription.payloadAsMember {
            guard let payloadMember = structureDefinition.members[payloadAsMember] else {
                fatalError("Unknown payload member.")
            }
            
            bodyTypeName = payloadMember.value.getNormalizedTypeName(forModel: model)
        } else {
            bodyTypeName = addBodyOperationHTTPResponseInput(
                hasBodyMembers: hasBodyMembers,
                operationPrefix: operationPrefix)
        }
        
        return bodyTypeName
    }
    
    private func addOperationHTTPResponseInput(
            structureDefinition: StructureDescription,
            inputDescription: OperationInputDescription,
            inputType: String,
            inputTypeName: String,
            operationPrefix: String,
            name: String,
            fileBuilder: FileBuilder,
            baseName: String) {
        var unassignedMembers = structureDefinition.members
        var bodyMembers = inputDescription.bodyFields
        let headersMembers = inputDescription.additionalHeaderFields
        var queryMembers = inputDescription.queryFields
        let pathMembers = inputDescription.pathFields
        var membersLocation: [String: LocationInput] = [:]
    
        inputDescription.bodyFields.forEach {
            unassignedMembers[$0] = nil
            membersLocation[$0] = .body
        }
        inputDescription.queryFields.forEach {
            unassignedMembers[$0] = nil
            membersLocation[$0] = .query
        }
        inputDescription.pathFields.forEach {
            unassignedMembers[$0] = nil
            membersLocation[$0] = .path
        }
        inputDescription.additionalHeaderFields.forEach {
            unassignedMembers[$0] = nil
            membersLocation[$0] = .headers
        }
    
        switch inputDescription.defaultInputLocation {
        case .body:
            unassignedMembers.forEach { membersLocation[$0.key] = .body }
            bodyMembers.append(contentsOf: unassignedMembers.keys)
        case .query:
            unassignedMembers.forEach { membersLocation[$0.key] = .query }
            queryMembers.append(contentsOf: unassignedMembers.keys)
        }
    
        let hasBodyMembers = !bodyMembers.isEmpty
        let hasQueryMembers = !queryMembers.isEmpty
        let hasPathMembers = !pathMembers.isEmpty
        let hasHeadersMembers = !headersMembers.isEmpty
        
        if hasBodyMembers && !hasQueryMembers
                && !hasPathMembers && !hasHeadersMembers {
            addSingleLocationOperationHttpInput(
                fileBuilder: fileBuilder, name: name,
                inputTypeName: inputTypeName, locationInput: .body)
        } else if !hasBodyMembers && hasQueryMembers
                && !hasPathMembers && !hasHeadersMembers {
            addSingleLocationOperationHttpInput(
                fileBuilder: fileBuilder, name: name,
                inputTypeName: inputTypeName, locationInput: .query)
        } else if !hasBodyMembers && !hasQueryMembers
                && hasPathMembers && !hasHeadersMembers {
            addSingleLocationOperationHttpInput(
                fileBuilder: fileBuilder, name: name,
                inputTypeName: inputTypeName, locationInput: .path)
        } else if !hasBodyMembers && !hasQueryMembers
                && !hasPathMembers && hasHeadersMembers {
            addSingleLocationOperationHttpInput(
                fileBuilder: fileBuilder, name: name,
                inputTypeName: inputTypeName, locationInput: .headers)
        } else {
            let bodyTypeName = getBodyTypeName(
                inputDescription: inputDescription,
                structureDefinition: structureDefinition,
                hasBodyMembers: hasBodyMembers, operationPrefix: operationPrefix)
            let headersTypeName = addHeadersOperationHTTPResponseInput(
                hasHeadersMembers: hasHeadersMembers, operationPrefix: operationPrefix)
            let queryTypeName = addQueryOperationHTTPResponseInput(
                hasQueryMembers: hasQueryMembers, operationPrefix: operationPrefix)
            let pathTypeName = addPathOperationHTTPResponseInput(
                hasPathMembers: hasPathMembers, operationPrefix: operationPrefix)
        
            let httpResponseInputTypes = HTTPResponseInputTypes(
                bodyTypeName: bodyTypeName, headersTypeName: headersTypeName,
                queryTypeName: queryTypeName, pathTypeName: pathTypeName,
                membersLocation: membersLocation,
                payloadAsMember: inputDescription.payloadAsMember)
        
            addResponseInputStructure(fileBuilder: fileBuilder, name: name,
                                      inputTypeName: inputTypeName,
                                      httpResponseInputTypes: httpResponseInputTypes)
        }
    }
    
    private func addSingleLocationOperationHttpInput(
            fileBuilder: FileBuilder,
            name: String,
            inputTypeName: String,
            locationInput: LocationInput) {
        let providerToUse: String
        
        switch locationInput {
        case .body:
            providerToUse = "bodyDecodableProvider"
        case .headers:
            providerToUse = "headersDecodableProvider"
        case .query:
            providerToUse = "queryDecodableProvider"
        case .path:
            providerToUse = "pathDecodableProvider"
        }
        
        fileBuilder.appendLine("""
            
            /**
             Type to handle the http input to the \(name) operation.
             */
            extension \(inputTypeName): OperationHTTP1InputProtocol {
                public typealias QueryType = \(inputTypeName)
                public typealias PathType = \(inputTypeName)
                public typealias BodyType = \(inputTypeName)
                public typealias HeadersType = \(inputTypeName)
            
                public static func compose(queryDecodableProvider: () throws -> QueryType,
                                           pathDecodableProvider: () throws -> PathType,
                                           bodyDecodableProvider: () throws -> BodyType,
                                           headersDecodableProvider: () throws -> HeadersType) throws -> \(inputTypeName) {
                    return try \(providerToUse)()
                }
            }
            """)
    }
}
