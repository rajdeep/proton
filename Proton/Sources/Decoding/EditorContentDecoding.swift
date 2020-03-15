//
//  EditorContentDecoding.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import CoreServices
import Foundation
import UIKit

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

    /// Decodes the given value to `NSAttributedString`
    /// - Parameters:
    ///   - mode: Mode for decoding
    ///   - maxSize: Maximum available size of the container in which the content will be rendered.
    ///   - value: Value to decode.
    func decode(mode: EditorContentMode, maxSize: CGSize, value: TypeToDecode) -> NSAttributedString
}

/// A type-erased implementation of `EditorContentDecoding`
/// - SeeAlso:
/// `EditorContentDecoding`
public struct AnyEditorContentDecoding<T>: EditorContentDecoding {
    let decoding: (EditorContentMode, CGSize, T) -> NSAttributedString

    /// Initializes AnyEditorContentDecoding
    /// - Parameter decoder: Decoder to use
    public init<D: EditorContentDecoding>(_ decoder: D) where D.TypeToDecode == T {
        decoding = decoder.decode
    }

    /// Decodes the given value to `NSAttributedString`
    /// - Parameters:
    ///   - mode: Mode for decoding
    ///   - maxSize: Maximum available size of the container in which the content will be rendered.
    ///   - value: Value to decode.
    public func decode(mode: EditorContentMode, maxSize: CGSize, value: T) -> NSAttributedString {
        return decoding(mode, maxSize, value)
    }
}
