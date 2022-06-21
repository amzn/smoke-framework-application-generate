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
//  TriviaListBuilder.swift
//  SwiftSyntaxExtensions
//

import SwiftSyntax

@resultBuilder
public struct TriviaListBuilder {

  /// The type of individual statement expressions in the transformed function,
  /// which defaults to Component if buildExpression() is not provided.
  public typealias Expression = TriviaPiece

  /// The type of a partial result, which will be carried through all of the
  /// build methods.
  public typealias Component = [TriviaPiece]

  /// The type of the final returned result, which defaults to Component if
  /// buildFinalResult() is not provided.
  public typealias FinalResult = ExpressibleAsTriviaPieceList

  /// Required by every result builder to build combined results from
  /// statement blocks.
  public static func buildBlock(_ components: Component...) -> Component {
    return components.flatMap { $0 }
  }

  /// If declared, provides contextual type information for statement
  /// expressions to translate them into partial results.
  public static func buildExpression(_ expression: Expression) -> Component {
    return [expression]
  }
    
  /// Provide the ability to an expression that returns an `ExpressibleAsCodeBlockItemList`
  /// such as another @CodeBlockItemListBuilder
  public static func buildExpression(_ expression: ExpressibleAsTriviaPieceList) -> Component {
    return expression.createTriviaPieceList()
  }

  /// Enables support for `if` statements that do not have an `else`.
  public static func buildOptional(_ component: Component?) -> Component {
    return component ?? []
  }

  /// With buildEither(second:), enables support for 'if-else' and 'switch'
  /// statements by folding conditional results into a single result.
  public static func buildEither(first component: Component) -> Component {
    return component
  }

  /// With buildEither(first:), enables support for 'if-else' and 'switch'
  /// statements by folding conditional results into a single result.
  public static func buildEither(second component: Component) -> Component {
    return component
  }

  /// Enables support for 'for..in' loops by combining the
  /// results of all iterations into a single result.
  public static func buildArray(_ components: [Component]) -> Component {
    return components.flatMap { $0 }
  }

  /// If declared, this will be called on the partial result of an 'if
  /// #available' block to allow the result builder to erase type
  /// information.
  public static func buildLimitedAvailability(_ component: Component) -> Component {
    return component
  }

  /// If declared, this will be called on the partial result from the outermost
  /// block statement to produce the final returned result.
  public static func buildFinalResult(_ component: Component) -> FinalResult {
    return component
  }
}
