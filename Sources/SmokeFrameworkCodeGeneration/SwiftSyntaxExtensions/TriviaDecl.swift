// Copyright 2019-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
//  TriviaDecl.swift
//  SwiftSyntaxExtensions
//

import SwiftSyntax
import SwiftSyntaxBuilder

public protocol ExpressibleAsTriviaDecl: ExpressibleAsDeclBuildable {
    func createTriviaDecl() -> TriviaDecl
}

public extension ExpressibleAsTriviaDecl {
    func createDeclBuildable() -> DeclBuildable {
        return self.createTriviaDecl()
    }
}

public typealias Comments = TriviaDecl

public func EmptyLine() -> TriviaDecl {
    return .init{ TriviaPiece.spaces(1) }
}

public struct TriviaDecl: DeclBuildable, ExpressibleAsTriviaDecl {
    let triviaPieceList: ExpressibleAsTriviaPieceList

    /// Creates a `TriviaDecl` using the provided parameters.
    /// - Parameters:
    ///   - trivia:
    public init(triviaPieceList: ExpressibleAsTriviaPieceList) {
        self.triviaPieceList = triviaPieceList
    }
    
    /// A convenience initializer that allows:
    ///  - Initializing syntax collections using result builders
    ///  - Initializing tokens without default text using strings
    public init(
        @TriviaListBuilder triviaBuilder: () -> ExpressibleAsTriviaPieceList = { [] })
    {
        self.init(triviaPieceList: triviaBuilder())
    }

    func buildTriviaDecl(format: Format, leadingTrivia: Trivia? = nil) -> InitializerDeclSyntax {
        let trivia = Trivia(pieces: self.triviaPieceList.createTriviaPieceList())
        let token = SyntaxFactory.makeToken(.unknown(""), presence: .present,
                                            trailingTrivia: trivia)
        
        let parameterList = SyntaxFactory.makeFunctionParameterList([])
        let parameters = SyntaxFactory.makeParameterClause(leftParen: .unknown(""),
                                                           parameterList: parameterList,
                                                           rightParen: .unknown(""))
        
        let result = SyntaxFactory.makeInitializerDecl(attributes: nil, modifiers: nil,
                                                       initKeyword: token, optionalMark: nil, genericParameterClause: nil, parameters: parameters, throwsOrRethrowsKeyword: nil, genericWhereClause: nil, body: nil)
        
        if let leadingTrivia = leadingTrivia {
            return result.withLeadingTrivia(leadingTrivia + (result.leadingTrivia ?? []))
        } else {
            return result
        }
    }

    /// Conformance to `DeclBuildable`.
    public func buildDecl(format: Format, leadingTrivia: Trivia? = nil) -> DeclSyntax {
        let result = buildTriviaDecl(format: format, leadingTrivia: leadingTrivia)
        return DeclSyntax(result)
    }

    /// Conformance to `ExpressibleAsTriviaDecl`.
    public func createTriviaDecl() -> TriviaDecl {
        return self
    }

    /// `TriviaDecl` might conform to `ExpressibleAsDeclBuildable` via different `ExpressibleAs*` paths.
    /// Thus, there are multiple default implementations for `createDeclBuildable`, some of which perform conversions through `ExpressibleAs*` protocols.
    /// To resolve the ambiguity, provide a fixed implementation that doesn't perform any conversions.
    public func createDeclBuildable() -> DeclBuildable {
        return self
    }

    /// `TriviaDecl` might conform to `SyntaxBuildable` via different `ExpressibleAs*` paths.
    /// Thus, there are multiple default implementations for `createSyntaxBuildable`, some of which perform conversions through `ExpressibleAs*` protocols.
    /// To resolve the ambiguity, provide a fixed implementation that doesn't perform any conversions.
    public func createSyntaxBuildable() -> SyntaxBuildable {
        return self
    }
}

extension SourceFileSyntax : DeclSyntaxProtocol {
    
}
