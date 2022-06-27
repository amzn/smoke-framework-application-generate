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
//  TupleOf.swift
//  SwiftSyntaxDSL
//

import SwiftSyntax
import SwiftSyntaxBuilder

public struct TupleOfContext: TupleOfBuildable {
    public var elementTypes: [ExpressibleAsTypeBuildable]
    public var wrapInParentType: (TupleType) -> TypeBuildable
}

public func TupleOf(_ type: ExpressibleAsTypeBuildable) -> some TupleOfBuildable {
    return TupleOfContext(elementTypes: [type], wrapInParentType: { $0 })
}

public extension TupleOfBuildable {
    func And(_ type: ExpressibleAsTypeBuildable) -> some TupleOfBuildable {
        var context = self
        context.elementTypes += [type]
        return context
    }
}

public protocol TupleOfBuildable: TypeBuildable {
    var elementTypes: [ExpressibleAsTypeBuildable] { get set }
    var wrapInParentType: (TupleType) -> TypeBuildable { get }
}

extension TupleOfBuildable {
    private func getTypeBuildable() -> TypeBuildable {
        let elements = self.elementTypes.enumerated().map { (index, type) in
            return TupleTypeElement(type: type,
                                    trailingComma: (index == self.elementTypes.count - 1) ? nil : TokenSyntax.comma)
        }
        
        let tupleType = TupleType(elements: TupleTypeElementList(elements))
        return self.wrapInParentType(tupleType)
    }
    
    public func buildType(format: Format, leadingTrivia: Trivia?) -> TypeSyntax {
        let typeBuildable = getTypeBuildable()
        
        return typeBuildable.buildType(format: format, leadingTrivia: leadingTrivia)
    }
    
    public func buildSyntax(format: Format, leadingTrivia: Trivia?) -> Syntax {
        let typeBuildable = getTypeBuildable()
        
        return typeBuildable.buildSyntax(format: format, leadingTrivia: leadingTrivia)
    }
    
    public func createSyntaxBuildable() -> SyntaxBuildable {
        let typeBuildable = getTypeBuildable()
        
        return typeBuildable.createSyntaxBuildable()
    }
}
