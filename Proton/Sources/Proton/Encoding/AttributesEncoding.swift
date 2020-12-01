//
//  AttributesEncoding.swift
//  Proton
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

/// Describes an encoder for a content type in Editor. This can be used in conjunction with `AnyEditorTextEncoding`
/// to register various encoders for each of the supported content types.
/// ### Usage Example ###
///```
/// struct ParagraphEncoder: EditorTextEncoding {
///     func encode(name: EditorContent.Name, string: NSAttributedString) -> JSON {
///         var paragraph = JSON()
///         paragraph.type = name.rawValue
///         if let style = string.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
///             paragraph[style.key] = style.value
///         }
///         paragraph.contents = contentsFrom(string)
///        return paragraph
///     }
/// }
///```
/// - SeeAlso:
/// `EditorContentEncoder`
public protocol EditorTextEncoding {
    associatedtype EncodedType

    /// Encodes the given attributed string to `EncodedType`
    /// - Parameters:
    ///   - name: Name of the content to encode
    ///   - string: Attributed string to encode
    func encode(name: EditorContent.Name, string: NSAttributedString) -> EncodedType
}

/// /// A type-erased implementation of `EditorTextEncoding`
/// - SeeAlso:
/// `EditorTextEncoding`
public struct AnyEditorTextEncoding<T>: EditorTextEncoding {
    public typealias EncodedType = T
    let encoding: (_ name: EditorContent.Name, _ string: NSAttributedString) -> T

    /// Initializes the Encoder
    /// - Parameter encoder: Encoder implementation to use
    public init<E: EditorTextEncoding>(_ encoder: E) where E.EncodedType == T {
        encoding = encoder.encode
    }

    /// Encodes contents based on concrete encoder provided during initialization
    /// - Parameters:
    ///   - name: Content name
    ///   - string: Attributed String to be encoded
    public func encode(name: EditorContent.Name, string: NSAttributedString) -> T {
        return encoding(name, string)
    }
}

/// Describes an object capable of encoding contents of at `Attachment`
public protocol AttachmentEncoding {
    associatedtype EncodedType

    /// Encodes given `Attachment` content view to given type
    /// - Parameters:
    ///   - name: Name of the content
    ///   - view: Attachment content view
    func encode(name: EditorContent.Name, view: UIView) -> EncodedType
}

/// A type-erased implementation of `AttachmentEncoding`.
public struct AnyEditorContentAttachmentEncoding<T>: AttachmentEncoding {
    public typealias EncodedType = T
    let encoding: (_ name: EditorContent.Name, _ view: UIView) -> T

    /// Initializes the Encoder
    /// - Parameter encoder: Encoder implementation to use
    public init<E: AttachmentEncoding>(_ encoder: E) where E.EncodedType == T {
        encoding = encoder.encode
    }

    /// Encodes contents based on concrete encoder provided during initialization
    /// - Parameters:
    ///   - name: Content name
    ///   - string: Attachment view to be encoded
    public func encode(name: EditorContent.Name, view: UIView) -> T {
        return encoding(name, view)
    }
}
