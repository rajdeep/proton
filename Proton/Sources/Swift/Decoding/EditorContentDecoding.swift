//
//  EditorContentDecoding.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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
import UIKit
import CoreServices

/// Content mode for `Editor`. This may be used while decoding the content for the Editor/Renderer to let the Decoder know
/// which mode the content is being decoded for. For e.g. you may  want to have different decoded value based on whether the
/// content is going to be displayed in `EditorView` or `RendererView`
/// - SeeAlso:
/// `EditorContentDecoding`
public enum EditorContentMode {
    case editor
    case renderer
}

/// An object capable of decoding the given type of content into `NSAttributedString` for using in `EditorView` or the `RendererView`.
public protocol EditorContentDecoding {
    associatedtype TypeToDecode
    associatedtype DecodingContext

    /// Decodes the given value to `NSAttributedString`
    /// - Parameters:
    ///   - mode: Mode for decoding
    ///   - maxSize: Maximum available size of the container in which the content will be rendered.
    ///   - value: Value to decode.
    ///   - context: Context used for decoding.
    func decode(mode: EditorContentMode, maxSize: CGSize, value: TypeToDecode, context: DecodingContext) throws -> NSAttributedString
}

/// A type-erased implementation of `EditorContentDecoding`
/// - SeeAlso:
/// `EditorContentDecoding`
public struct AnyEditorContentDecoding<T, C>: EditorContentDecoding {
    let decoding: (EditorContentMode, CGSize, T, C) throws -> NSAttributedString

    /// Initializes AnyEditorContentDecoding
    /// - Parameter decoder: Decoder to use
    public init<D: EditorContentDecoding>(_ decoder: D) where D.TypeToDecode == T, D.DecodingContext == C {
        decoding = decoder.decode
    }

   /// Decodes the given value to `NSAttributedString`
    /// - Parameters:
    ///   - mode: Mode for decoding
    ///   - maxSize: Maximum available size of the container in which the content will be rendered.
    ///   - value: Value to decode.
    ///   - context: Context used for decoding.
    public func decode(mode: EditorContentMode, maxSize: CGSize, value: T, context: C) throws -> NSAttributedString {
        return try decoding(mode, maxSize, value, context)
    }
}
