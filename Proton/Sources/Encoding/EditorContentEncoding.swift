//
//  EditorContentEncoding.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

/// An object capable of encoding `EditorContent` to given type.
public protocol EditorContentEncoding {
    associatedtype EncodedType
    func encode(_ content: EditorContent) -> EncodedType!
}

/// A generic encoder for encoding `EditorContent`. You may create encoders for individual types of contents in the `Editor`, and
/// use `EditorContentEncoder` to register and encode the all the contents of the given `EditorView`.
///
/// ### Usage Example ###
/// ```
/// typealias JSON = [String: Any]

/// struct JSONEncoder: EditorContentEncoder {
///     let textEncoders: [EditorContent.Name: AnyEditorTextEncoding<JSON>] = [
///         .paragraph: AnyEditorTextEncoding(ParagraphEncoder()),
///         .text: AnyEditorTextEncoding(TextEncoder())
///     ]

///     let attachmentEncoders: [EditorContent.Name: AnyEditorContentAttachmentEncoding<JSON>] = [
///        .panel: AnyEditorContentAttachmentEncoding(PanelEncoder()),
///        .media: AnyEditorContentAttachmentEncoding(MediaEncoder()),
///     ]
/// }
///
/// // Get the encoded content from the editor
/// let encodedContent = editor.transformContents(using: JSONEncoder())
/// ```
public protocol EditorContentEncoder: EditorContentEncoding {
    associatedtype T

    /// Encoders for text content i.e. NSAttributedString based content
    var textEncoders: [EditorContent.Name: AnyEditorTextEncoding<T>] { get }

    /// Encoders for attachment types
    var attachmentEncoders: [EditorContent.Name: AnyEditorContentAttachmentEncoding<T>] { get }

    /// Encodes the given content.
    /// - Note:
    /// A default implementation is already provided which automatically uses correct encoder based on the content to encode.
    /// The default implementation should be sufficient for most unless you need to add additional behaviour like logging. analytics etc.
    /// - Parameter content: Content to encode
    func encode(_ content: EditorContent) -> T!
}

public extension EditorContentEncoder {
    func encode(_ content: EditorContent) -> T! {
        switch content.type {
        case .viewOnly:
            return nil
        case let .attachment(name, contentView, _):
            guard let encodable = attachmentEncoders[name] else { return nil }
            return encodable.encode(name: name, view: contentView)
        case let .text(name, attributedString):
            guard let encodable = textEncoders[name] else {  return nil }
            return encodable.encode(name: name, string: attributedString)
        }
    }
}
