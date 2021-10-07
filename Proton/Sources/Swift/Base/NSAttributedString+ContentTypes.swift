//
//  NSAttributedString+ContentTypes.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
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

extension NSAttributedString.Key {
    static let viewOnly = NSAttributedString.Key("_viewOnly")

    static let isBlockAttachment = NSAttributedString.Key("_isBlockAttachment")
    static let isInlineAttachment = NSAttributedString.Key("_isInlineAttachment")
}

public extension NSAttributedString.Key {
    /// Applying this attribute makes the range of text act as a single block/unit.
    /// The content can still be deleted and selected but cursor cannot be moved into textBlock range
    /// using taps or mouse/keys (macOS Catalyst). Selection and delete on part of the range works atomically on the entire range.
    /// - Note: In successive ranges, if the `textblock` is provided with a value type with same value e.g. `true`, the behaviour
    /// will be combined for the ranges as one text block i.e. it will work as single textblock even though the attribute was added separately.
    /// However, if the value provided is different in successive ranges, these will work independent of each other even if one range
    /// immediately follows the other.
    static let textBlock = NSAttributedString.Key("_textBlock")

    /// Identifies block based attributes. A block acts as a container for other content types. For e.g. a Paragraph is a block content
    /// that contains Text as inline content. A block content may contain multiple inline contents of different types.
    /// This is utilized only when using `editor.contents(in:)` or `NSAttributedString.enumerateContents(in:)`.
    /// Both these utility functions allow breaking content in the editor into sub-parts that can be used to encode content.
    /// - SeeAlso:
    /// `EditorContentEncoder`
    /// `EditorView`
    static let blockContentType = NSAttributedString.Key("_blockContentType")

    /// Identifies inline content attributes. An inline acts as a content in another content types. For e.g. an emoji is an inline content
    /// that may be contained in a Paragraph along side another inline content of Text.
    /// This is utilized only when using  using `NSAttributedString.enumerateInlineContents(in:)`.
    /// This utility functions allow breaking content in a block based content string into sub-parts that can then be used to encode content.
    /// - SeeAlso:
    /// `EditorContentEncoder`
    /// `EditorView`
    static let inlineContentType = NSAttributedString.Key("_inlineContentType")

    /// Additional style attribute for background color. Using this attribute in addition to `backgroundColor` attribute allows applying
    /// shadow and corner radius to the background.
    /// - Note:
    /// This attribute only takes effect with `.backgroundColor`. In absence of `.backgroundColor`, this attribute has no effect.
    static let backgroundStyle = NSAttributedString.Key("_backgroundStyle")

    /// Attribute denoting the range as a list item. This attribute enables use of `ListTextProcessor` to indent/outdent list
    /// using tab/shift-tab (macOS) as well as create a new list item on hitting enter key.
    static let listItem = NSAttributedString.Key("_listItem")

    /// When applied to a new line char alongside `listItem` attribute, skips the rendering of list marker on subsequent line.
    static let skipNextListMarker = NSAttributedString.Key("_skipNextListMarker")
}
