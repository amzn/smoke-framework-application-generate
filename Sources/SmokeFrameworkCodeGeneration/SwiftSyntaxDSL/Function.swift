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
//  Function.swift
//  SwiftSyntaxDSL
//

import SwiftSyntax
import SwiftSyntaxBuilder

public struct FunctionContext: IdentiferFinalizedFunction {
    public let identifier: TokenSyntax
    public let staticSyntax: TokenSyntax?
    public var genericParameters: [GenericParameter]
    public var functionParameters: [FunctionParameter]
    public var genericRequirementBodies: [SyntaxBuildable]
    public var bodyBuilder: () -> CodeBlockItemList?
}

public extension StaticContext {
    func Function(_ identifier: TokenSyntax) -> some IdentiferFinalizedFunction {
        return FunctionContext(identifier: identifier,
                               staticSyntax: self.staticSyntax,
                               genericParameters: [],
                               functionParameters: [],
                               genericRequirementBodies: [],
                               bodyBuilder: { CodeBlockItemList([]) })
    }
    
    func Function(_ identifier: String) -> some IdentiferFinalizedFunction {
        return FunctionContext(identifier: identifier.asToken(),
                               staticSyntax: self.staticSyntax,
                               genericParameters: [],
                               functionParameters: [],
                               genericRequirementBodies: [],
                               bodyBuilder: { CodeBlockItemList([]) })
    }
}

public protocol IdentiferFinalizedFunction: GenericsFinalizedFunction {
    var genericParameters: [GenericParameter] { get set }
}

public extension IdentiferFinalizedFunction {
    func GenericFor(_ identifier: TokenSyntax, extending inheritedType: ExpressibleAsTypeBuildable? = nil) -> some IdentiferFinalizedFunction {
        let newGenericParameter = GenericParameter(name: identifier,
                                                   colon: TokenSyntax.colon,
                                                   inheritedType: inheritedType)
        
        var context = self
        context.genericParameters += [newGenericParameter]
        return context
    }
    
    func GenericFor(_ identifier: String, extending inheritedType: ExpressibleAsTypeBuildable? = nil) -> some IdentiferFinalizedFunction {
        return GenericFor(identifier.asToken(), extending: inheritedType)
    }
    
    func GenericFor(_ identifier: TokenSyntax, whichIsA inheritedType: ExpressibleAsTypeBuildable? = nil,
                    @CodeBlockItemListBuilder bodyBuilder: @escaping () -> CodeBlockItemList?) -> some FunctionBuildable {
        let newGenericParameter = GenericParameter(name: identifier,
                                                   colon: TokenSyntax.colon,
                                                   inheritedType: inheritedType)
        
        var context = self
        context.genericParameters += [newGenericParameter]
        context.bodyBuilder = bodyBuilder
        return context
    }
    
    func GenericFor(_ identifier: String, whichIsA inheritedType: ExpressibleAsTypeBuildable? = nil,
                    @CodeBlockItemListBuilder bodyBuilder: () -> CodeBlockItemList?) -> some FunctionBuildable {
        return GenericFor(identifier.asToken(), extending: inheritedType)
    }
}

public protocol GenericsFinalizedFunction: WhereFinalizedFunction {
    var functionParameters: [FunctionParameter] { get set }
}

public extension GenericsFinalizedFunction {
    func Input(_ identifier: TokenSyntax, whichIsA inheritedType: ExpressibleAsTypeBuildable? = nil) -> some GenericsFinalizedFunction {
        let newParameter = FunctionParameter(firstName: identifier,
                                             colon: TokenSyntax.colon,
                                             type: inheritedType,
                                             attributesBuilder: {  }
        )
        
        var context = self
        context.functionParameters += [newParameter]
        return context
    }
    
    func Input(_ identifier: String, whichIsA inheritedType: ExpressibleAsTypeBuildable? = nil) -> some GenericsFinalizedFunction {
        return Input(identifier.asToken(), whichIsA: inheritedType)
    }
    
    func Input(_ identifier: TokenSyntax, whichIsA inheritedType: ExpressibleAsTypeBuildable? = nil,
               @CodeBlockItemListBuilder bodyBuilder: @escaping () -> CodeBlockItemList?) -> some FunctionBuildable {
        let newParameter = FunctionParameter(firstName: identifier,
                                             colon: TokenSyntax.colon,
                                             type: inheritedType,
                                             attributesBuilder: {  }
        )
        
        var context = self
        context.functionParameters += [newParameter]
        context.bodyBuilder = bodyBuilder
        return context
    }
    
    func Input(_ identifier: String, whichIsA inheritedType: ExpressibleAsTypeBuildable? = nil,
               @CodeBlockItemListBuilder bodyBuilder: () -> CodeBlockItemList?) -> some FunctionBuildable {
        return Input(identifier.asToken(), whichIsA: inheritedType)
    }
}

public protocol WhereFinalizedFunction: FunctionBuildable {
    var genericRequirementBodies: [SyntaxBuildable] { get set }
    var bodyBuilder: () -> CodeBlockItemList? { get set }
}

public extension WhereFinalizedFunction {
    func Where(_ left: ExpressibleAsTypeBuildable, isSameAs right: ExpressibleAsTypeBuildable) -> some WhereFinalizedFunction {
        let genericRequirementBody = SameTypeRequirement(leftTypeIdentifier: left,
                                                         equalityToken: " == ".asToken(),
                                                         rightTypeIdentifier: right
                                                                             )
        
        var context = self
        context.genericRequirementBodies += [genericRequirementBody]
        return context
    }
    
    func Where(_ left: ExpressibleAsTypeBuildable, isSameAs right: ExpressibleAsTypeBuildable,
               @CodeBlockItemListBuilder bodyBuilder: @escaping () -> CodeBlockItemList?) -> some FunctionBuildable {
        let genericRequirementBody = SameTypeRequirement(leftTypeIdentifier: left,
                                                         equalityToken: " == ".asToken(),
                                                         rightTypeIdentifier: right
                                                                             )
        
        var context = self
        context.genericRequirementBodies += [genericRequirementBody]
        context.bodyBuilder = bodyBuilder
        return context
    }
}

public protocol FunctionBuildable: ExpressibleAsCodeBlockItem, ExpressibleAsMemberDeclListItem {
    var identifier: TokenSyntax { get }
    var staticSyntax: TokenSyntax? { get }
    var genericParameters: [GenericParameter] { get }
    var functionParameters: [FunctionParameter] { get }
    var genericRequirementBodies: [SyntaxBuildable] { get }
    var bodyBuilder: () -> CodeBlockItemList? { get }
}

extension FunctionBuildable {
    private func createDecal() -> FunctionDecl {
        let genericRequirements = self.genericRequirementBodies.enumerated().map { (index, body) in
            return GenericRequirement(body: body,
                                      trailingComma: (index == self.genericRequirementBodies.count - 1) ? nil : TokenSyntax.comma)
        }
        
        let body: CodeBlock?
        if let builtBody = self.bodyBuilder() {
            body = CodeBlock(leftBrace: TokenSyntax.`leftBrace`
                                .withLeadingTrivia(.spaces(1)),
                             statements: builtBody,
                             rightBrace: TokenSyntax.`rightBrace`)
        } else {
            body = nil
        }
        
        return FunctionDecl(identifier: self.identifier,
                            genericParameterClause: GenericParameterClause(leftAngleBracket: SyntaxFactory.makeLeftAngleToken(),
                                                                           genericParameterList: GenericParameterList(genericParameters),
                                                                           rightAngleBracket: SyntaxFactory.makeRightAngleToken()),
                            signature: FunctionSignature(
                               input: ParameterClause(
                                   parameterList: FunctionParameterList(functionParameters)
                               )
                            ),
                            genericWhereClause: GenericWhereClause(whereKeyword: TokenSyntax.`where`
                                                                       .withLeadingTrivia(.spaces(1)),
                                                                   requirementList: GenericRequirementList(genericRequirements)),
                            body: body,
                            modifiersBuilder: {
                                if let staticSyntax = staticSyntax {
                                    staticSyntax
                                }
                            })
    }
    
    public func createSyntaxBuildable() -> SyntaxBuildable {
        return createDecal()
    }
    
    public func createCodeBlockItem() -> CodeBlockItem {
        return createDecal().createCodeBlockItem()
    }
    
    public func createMemberDeclListItem() -> MemberDeclListItem {
        return MemberDeclListItem(decl: createDecal())
    }
}

/*
 MemberDeclBlock(leftBrace: TokenSyntax.`leftBrace`
                            .withLeadingTrivia(.spaces(1)),
                          members: self.membersBuilder(),
                          rightBrace: TokenSyntax.`rightBrace`)
 */
