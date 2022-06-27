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
//  IfOrLet.swift
//  SwiftSyntaxDSL
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct ChildContext {
    unowned let storage: IfOrLetPatternContextStorage
}

public class IfOrLetContext: IfOrLetBuildable {
    let ifOrLetSyntax : TokenSyntax
    var childContexts: [ChildContext]
    
    init(ifOrLetSyntax : TokenSyntax) {
        self.ifOrLetSyntax = ifOrLetSyntax
        self.childContexts = []
    }
}

public struct IfOrLetPatternContext: IfOrLetPatternWithNoTypeNoInitializerBuildable {
    public let previousPatternStorage: [IfOrLetPatternContextStorage]
    public let storage: IfOrLetPatternContextStorage
    
    var pattern: ExpressibleAsPatternBuildable {
        return self.storage.pattern
    }
    
    public var parent: IfOrLetContext {
        return self.storage.parent
    }
    
    public var typeAnnotation: TypeAnnotation? {
        get {
            return self.storage.typeAnnotation
        }
        set {
            self.storage.typeAnnotation = newValue
        }
    }
    
    public var initializer: InitializerClause? {
        get {
            return self.storage.initializer
        }
        set {
            self.storage.initializer = newValue
        }
    }
}

public class IfOrLetPatternContextStorage {
    let pattern: ExpressibleAsPatternBuildable
    public let parent: IfOrLetContext
    public var typeAnnotation: TypeAnnotation?
    public var initializer: InitializerClause?
    
    init(pattern: ExpressibleAsPatternBuildable,
         parent: IfOrLetContext) {
        self.pattern = pattern
        self.parent = parent
        self.typeAnnotation = nil
        self.initializer = nil
    }
}

public func Let(_ pattern: ExpressibleAsPatternBuildable) -> some IfOrLetPatternWithNoTypeNoInitializerBuildable {
    let parentContext = IfOrLetContext(ifOrLetSyntax: TokenSyntax.let)
    
    let storage = IfOrLetPatternContextStorage(pattern: pattern, parent: parentContext)
    let context = IfOrLetPatternContext(previousPatternStorage: [], storage: storage)
    parentContext.childContexts += [ChildContext(storage: storage)]
    
    return context
}

public protocol IfOrLetPatternWithNoTypeNoInitializerBuildable: IfOrLetPatternWithWithTypeNoInitializerBuildable {
    var typeAnnotation: TypeAnnotation? { get set }
}

public extension IfOrLetPatternWithNoTypeNoInitializerBuildable {
    func WithType(_ type: TypeBuildable) -> some IfOrLetPatternWithWithTypeNoInitializerBuildable {
        var context = self
        context.typeAnnotation = TypeAnnotation(type: type)
        
        return context
    }
}

public protocol IfOrLetPatternWithWithTypeNoInitializerBuildable: IfOrLetPatternBuildable {
    var initializer: InitializerClause? { get set }
}

public extension IfOrLetPatternWithWithTypeNoInitializerBuildable {
    func WithValue(_ expr: ExprBuildable) -> some IfOrLetPatternBuildable {
        var context = self
        context.initializer = InitializerClause(value: expr)

        return context
    }
}

public protocol IfOrLetPatternBuildable: ExpressibleAsCodeBlockItem, ExpressibleAsMemberDeclListItem {
    var parent: IfOrLetContext { get }
    var previousPatternStorage: [IfOrLetPatternContextStorage] { get }
    var storage: IfOrLetPatternContextStorage { get }
}

extension IfOrLetPatternBuildable {
    public func And(_ pattern: ExpressibleAsPatternBuildable) -> some IfOrLetPatternWithNoTypeNoInitializerBuildable {
        let parentContext = self.parent
        
        let storage = IfOrLetPatternContextStorage(pattern: pattern, parent: parentContext)
        let context = IfOrLetPatternContext(previousPatternStorage: self.previousPatternStorage + [self.storage],
                                            storage: storage)
        parentContext.childContexts += [ChildContext(storage: storage)]
        
        return context
    }
    
    public func createSyntaxBuildable() -> SyntaxBuildable {
        return self.parent.createDecal()
    }
    
    public func createCodeBlockItem() -> CodeBlockItem {
        return self.parent.createDecal().createCodeBlockItem()
    }
    
    public func createMemberDeclListItem() -> MemberDeclListItem {
        return MemberDeclListItem(decl: self.parent.createDecal())
    }
}

protocol IfOrLetBuildable {
    var ifOrLetSyntax : TokenSyntax { get }
    var childContexts: [ChildContext] { get }
}

extension IfOrLetBuildable {
    func createDecal() -> VariableDecl {
        let bindings: [PatternBinding] = self.childContexts.enumerated().map { (index, childContext) in
            let storage = childContext.storage
            return PatternBinding(pattern: storage.pattern,
                                  typeAnnotation: storage.typeAnnotation,
                                  initializer: storage.initializer,
                                  trailingComma: (index == self.childContexts.count - 1) ? nil : TokenSyntax.comma)
        }
        
        return VariableDecl(letOrVarKeyword: self.ifOrLetSyntax,
                            bindings: PatternBindingList(bindings))
    }
}
