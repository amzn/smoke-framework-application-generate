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
//  ServiceModelCodeGenerator+createInputStructureStubVariable.swift
//  SmokeFrameworkCodeGeneration
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities

public extension ServiceModelCodeGenerator {
    internal enum LocationInput {
        case body
        case headers
        case query
        case path
    }
    
    internal func createInputStructureStubVariable(
            type: String,
            fileBuilder: FileBuilder,
            declarationPrefix: String,
            memberLocation: [String: LocationInput],
            payloadAsMember: String?) {
        var outputLines: [String] = []
        let baseName = applicationDescription.baseName
        
        // if there isn't actually a structure of the type, this is a fatal
        guard let structureDefinition = model.structureDescriptions[type] else {
            fatalError("No structure found of type '\(type)'")
        }
        
        // sort the members in alphabetical order for output
        let sortedMembers = structureDefinition.members.sorted { entry1, entry2 in
            return entry1.value.position < entry2.value.position
        }
        
        if sortedMembers.isEmpty {
            outputLines.append("\(declarationPrefix) \(baseName)Model.\(type)()")
        } else {
            outputLines.append("\(declarationPrefix) \(baseName)Model.\(type)(")
        }
        
        // iterate through each property
        for (index, entry) in sortedMembers.enumerated() {
            createInputStructureMemberStubVariable(
                modelTypeName: entry.key, index: index, enclosingType: type, structureDefinition: structureDefinition,
                memberLocation: memberLocation, payloadAsMember: payloadAsMember, outputLines: &outputLines)
        }
        
        // output the declaration
        if outputLines.isEmpty {
            fileBuilder.appendLine("\(declarationPrefix) \(baseName)Model.\(type)()")
        } else {
            outputLines.forEach { line in fileBuilder.appendLine(line) }
        }
    }
    
    private func createInputStructureMemberStubVariable(modelTypeName: String, index: Int, enclosingType: String,
                                                        structureDefinition: StructureDescription,
                                                        memberLocation: [String: LocationInput], payloadAsMember: String?,
                                                        outputLines: inout [String]) {
        let parameterName = getNormalizedVariableName(modelTypeName: modelTypeName,
                                                      inStructure: enclosingType,
                                                      reservedWordsAllowed: true)
        
        let prefix = "    "
        let postfix: String
        if index == structureDefinition.members.count - 1 {
            postfix = ")"
        } else {
            postfix = ","
        }
    
        guard let location = memberLocation[modelTypeName] else {
            fatalError("Unknown location for member.")
        }
    
        let value: String
        switch location {
        case .body:
            if let payloadAsMember = payloadAsMember {
                guard payloadAsMember == modelTypeName else {
                    fatalError("Body member \(modelTypeName) not part of payload")
                }
                
                value = "body"
            } else {
                value = "body.\(parameterName)"
            }
        case .headers:
            value = "headers.\(parameterName)"
        case .query:
            value = "query.\(parameterName)"
        case .path:
            value = "path.\(parameterName)"
        }
    
        outputLines.append("\(prefix)\(parameterName): \(value)\(postfix)")
    }
}
