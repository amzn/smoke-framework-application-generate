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
//  Extension.swift
//  SwiftSyntaxDSL
//

import SwiftSyntax
import SwiftSyntaxBuilder

public struct ExtensionContext: IdentiferFinalizedExtension {
    public let extendedType: ExpressibleAsTypeBuildable
    public let accessControlModiferSyntax : TokenSyntax?
    public var membersBuilder: () -> ExpressibleAsMemberDeclList
    public var inheritanceClause: ExpressibleAsTypeInheritanceClause?
}

func Extension(_ identifier: ExpressibleAsTypeBuildable) -> some IdentiferFinalizedExtension {
    return ExtensionContext(extendedType: identifier,
                            accessControlModiferSyntax: nil,
                            membersBuilder: { MemberDeclList([]) })
}

func Extension(_ identifier: ExpressibleAsTypeBuildable,
               @MemberDeclListBuilder membersBuilder: @escaping () -> ExpressibleAsMemberDeclList) -> some ExtensionBuildable {
    return ExtensionContext(extendedType: identifier,
                            accessControlModiferSyntax: nil,
                            membersBuilder: membersBuilder)
}

public extension AccessControlModiferContext {
    func Extension(_ identifier: ExpressibleAsTypeBuildable) -> some IdentiferFinalizedExtension {
        return ExtensionContext(extendedType: identifier,
                                accessControlModiferSyntax: self.accessControlModiferSyntax,
                                membersBuilder: { MemberDeclList([]) })
    }
    
    func Extension(_ identifier: ExpressibleAsTypeBuildable,
                   @MemberDeclListBuilder membersBuilder: @escaping () -> ExpressibleAsMemberDeclList) -> some ExtensionBuildable {
        return ExtensionContext(extendedType: identifier,
                                accessControlModiferSyntax: self.accessControlModiferSyntax,
                                membersBuilder: membersBuilder)
    }
}

public protocol IdentiferFinalizedExtension: ExtensionBuildable {
    var membersBuilder: () -> ExpressibleAsMemberDeclList { get set }
    var inheritanceClause: ExpressibleAsTypeInheritanceClause? { get set }
}

public extension IdentiferFinalizedExtension {
    func ConformsTo(_ typeName: ExpressibleAsTypeBuildable) -> some IdentiferFinalizedExtension {
        let inheritanceClause = TypeInheritanceClause {
            InheritedType(typeName: "OperationIdentity")
          }
        
        var context = self
        context.inheritanceClause = inheritanceClause
        return context
    }
    
    func ConformsTo(_ typeName: ExpressibleAsTypeBuildable,
                    @MemberDeclListBuilder membersBuilder: @escaping () -> ExpressibleAsMemberDeclList) -> some ExtensionBuildable {
        let inheritanceClause = TypeInheritanceClause {
            InheritedType(typeName: "OperationIdentity")
          }
        
        var context = self
        context.inheritanceClause = inheritanceClause
        context.membersBuilder = membersBuilder
        return context
    }
}

public protocol ExtensionBuildable: ExpressibleAsCodeBlockItem, ExpressibleAsMemberDeclListItem {
    var extendedType: ExpressibleAsTypeBuildable { get }
    var accessControlModiferSyntax : TokenSyntax? { get }
    var membersBuilder: () -> ExpressibleAsMemberDeclList { get }
    var inheritanceClause: ExpressibleAsTypeInheritanceClause? { get }
}

extension ExtensionBuildable {
    private func createDecal() -> ExtensionDecl {
        return ExtensionDecl(extendedType: self.extendedType,
                             inheritanceClause: inheritanceClause,
                             modifiersBuilder: {
                                if let accessControlModiferSyntax = self.accessControlModiferSyntax {
                                    accessControlModiferSyntax
                                }
                             },
                             membersBuilder: self.membersBuilder
                             )
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
