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
//  TupleWith.swift
//  SwiftSyntaxDSL
//

import SwiftSyntax
import SwiftSyntaxBuilder

public struct TupleWithContext: TupleWithBuildable {
    public var expressions: [ExpressibleAsExprBuildable]
    public var wrapInParentType: (TupleExpr) -> ExprBuildable
}

public func TupleWith(_ expression: ExpressibleAsExprBuildable) -> some TupleWithBuildable {
    return TupleWithContext(expressions: [expression], wrapInParentType: { $0 })
}

public extension TupleWithBuildable {
    func And(_ expression: ExpressibleAsExprBuildable) -> some TupleWithBuildable {
        var context = self
        context.expressions += [expression]
        return context
    }
}

public protocol TupleWithBuildable: ExprBuildable {
    var expressions: [ExpressibleAsExprBuildable] { get set }
    var wrapInParentType: (TupleExpr) -> ExprBuildable { get }
}

extension TupleWithBuildable {
    private func getExprBuildable() -> ExprBuildable {
        let expressions = self.expressions.enumerated().map { (index, expression) in
            return TupleExprElement(expression: expression,
                                    trailingComma: (index == self.expressions.count - 1) ? nil : TokenSyntax.comma)
        }
        
        let tupleExpr = TupleExpr(elementList: TupleExprElementList(expressions))
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
