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
//  ExpressibleAsTriviaPieceList.swift
//  SwiftSyntaxExtensions
//

import SwiftSyntax

public protocol ExpressibleAsTriviaPieceList {
  func createTriviaPieceList() -> [TriviaPiece]
}

extension Array: ExpressibleAsTriviaPieceList where Element == TriviaPiece {
    public func createTriviaPieceList() -> [TriviaPiece] {
        return self
    }
}

extension TokenSyntax {
  internal func with(leadingTriviaBuilder: () -> ExpressibleAsTriviaPieceList,
                     trailingTriviaBuilder: () -> ExpressibleAsTriviaPieceList) -> TokenSyntax {
    var token = self

    let leadingTrivia = leadingTriviaBuilder().createTriviaPieceList()
    if leadingTrivia.count > 0 {
      token = token.withLeadingTrivia(Trivia(pieces: leadingTrivia))
    }
        
    let trailingTrivia = trailingTriviaBuilder().createTriviaPieceList()
    if trailingTrivia.count > 0 {
      token = token.withTrailingTrivia(Trivia(pieces: trailingTrivia))
    }
      
    return token
  }
}
