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
//  ArrayWith.swift
//  SwiftSyntaxDSL
//

import SwiftSyntax
import SwiftSyntaxBuilder

public struct ArrayWithContext: ArrayWithBuildable {
    public var expressions: [ExpressibleAsExprBuildable]
    public var wrapInParentType: (ArrayExpr) -> ExprBuildable
}

public func ArrayWith(_ expression: ExpressibleAsExprBuildable) -> some ArrayWithBuildable {
    return ArrayWithContext(expressions: [expression], wrapInParentType: { $0 })
}

public func ArrayWith(contentsOf expressions: [ExpressibleAsExprBuildable]) -> some ArrayWithBuildable {
    return ArrayWithContext(expressions: expressions, wrapInParentType: { $0 })
}

public extension ArrayWithBuildable {
    func And(_ expression: ExpressibleAsExprBuildable) -> some ArrayWithBuildable {
        var context = self
        context.expressions += [expression]
        return context
    }
}

public protocol ArrayWithBuildable: ExprBuildable {
    var expressions: [ExpressibleAsExprBuildable] { get set }
    var wrapInParentType: (ArrayExpr) -> ExprBuildable { get }
}

extension ArrayWithBuildable {
    private func getExprBuildable() -> ExprBuildable {
        let expressions = self.expressions.enumerated().map { (index, element) in
            return ArrayElement(expression: element,
                                trailingComma: (index == self.expressions.count - 1) ? nil : TokenSyntax.comma)
        }
        
        let tupleExpr = ArrayExpr(elements: ArrayElementList(expressions))
        return self.wrapInParentType(tupleExpr)
    }
    
    public func buildExpr(format: Format, leadingTrivia: Trivia?) -> ExprSyntax {
        let exprBuildable = getExprBuildable()
        
        return exprBuildable.buildExpr(format: format, leadingTrivia: leadingTrivia)
    }
    
    public func buildSyntax(format: Format, leadingTrivia: Trivia?) -> Syntax {
        let exprBuildable = getExprBuildable()

        return exprBuildable.buildSyntax(format: format, leadingTrivia: leadingTrivia)
    }
    
    public func createSyntaxBuildable() -> SyntaxBuildable {
        let exprBuildable = getExprBuildable()

        return exprBuildable.createSyntaxBuildable()
    }
}
