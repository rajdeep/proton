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
    /// Applying this attribute with value of `true` to a range of text makes that text non-focusable.
    /// The content can still be deleted and selected but cursor cannot be moved to non-focusable range
    /// using taps or mouse/keys (macOS Catalyst)
    static let noFocus = NSAttributedString.Key("_noFocus")

    /// Identifies block based attributes. A block acts as a container for other content types. For e.g. a Paragraph is a block content
    /// that contains Text as inline content. A block content may contain multiple inline contents of different types.
    /// This is utilised only when using `editor.contents(in:)` or `NSAttributedString.enumerateContents(in:)`.
    /// Both these utility functions allow breaking content in the editor into sub-parts that can be used to encode content.
    /// - SeeAlso:
    /// `EditorContentEncoder`
    /// `EditorView`
    static let blockContentType = NSAttributedString.Key("_blockContentType")

    /// Identifies inline content attributes. An inline acts as a content in another content types. For e.g. an emoji is an inline content
    /// that may be contained in a Paragraph along side another inline content of Text.
    /// This is utilised only when using  using `NSAttributedString.enumerateInlineContents(in:)`.
    /// This utility functions allow breaking content in a block based content string into sub-parts that can then be used to encode content.
    /// - SeeAlso:
    /// `EditorContentEncoder`
    /// `EditorView`
    static let inlineContentType = NSAttributedString.Key("_inlineContentType")
}
