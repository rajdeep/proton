//
//  AsyncTextResolver.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 31/5/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


import Foundation

/// Result type for async text resolution
public enum AsyncTextResolvingResult {
    case apply(NSAttributedString, range: NSRange)
    case discard
}

/// An object capable of resolving text asynchronously to another representation. New representation may contain change in attributes or the string itself.
public protocol AsyncTextResolving {
    /// Name of the Resolver. This name must be applied to the range of text that requires async resolution with attribute key: `.asyncTextResolver`
    var name: String { get }

    /// Resolves the string to a different representation
    /// - Parameters:
    ///   - editor: Editor containing the attributed string
    ///   - range: Range of attributesString containing `.asyncTextResolver` attribute
    ///   - string: Substring of attributesString containing `.asyncTextResolver` attribute
    ///   - completion: Transformed result to be applied. `.apply` will replace the `range` in `Editor` with provided `attributedString`.
    ///   .`.discard` discards the operation.
    /// - Important: As part of resolution, `.asyncTextResolver` is removed from original range. If the content in original range has changed in
    /// the time it took for resolution, it is responsibility of consumer to cleanup dangling attribute, if any.
    func resolve(using editor: EditorView, range: NSRange, string: NSAttributedString, completion: @escaping (AsyncTextResolvingResult) -> Void)
}
