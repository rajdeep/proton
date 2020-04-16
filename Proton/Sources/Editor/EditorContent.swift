//
//  EditorContent.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
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

/// Type of attachment
public enum AttachmentType {
    case block
    case inline
}

/// Type of `EditorContent`
public enum EditorContentType {
    case text(name: EditorContent.Name, attributedString: NSAttributedString)
    case attachment(name: EditorContent.Name, attachment: Attachment, contentView: UIView, type: AttachmentType)
    case viewOnly
}

/// Defines a content type for `Editor`. This may be used to serialize the contents of an `Editor` via enumerating through the contents of the `Editor`.
public struct EditorContent {

    /// Type of `EditorContent`
    public let type: EditorContentType

    /// Range within the `Editor` for this content
    public let enclosingRange: NSRange?

    init(type: EditorContentType) {
        self.type = type
        self.enclosingRange = nil
    }

    init(type: EditorContentType, enclosingRange: NSRange) {
        self.type = type
        self.enclosingRange = enclosingRange
    }
}

public extension EditorContent {

    /// Name for the content within the Editor. All the content (text  and attachments) must have
    /// a name. By default, text contained in Editor is considered a paragraph.
    struct Name: Hashable, Equatable, RawRepresentable {
        public var rawValue: String

        public static let paragraph = Name("_paragraph")
        public static let viewOnly = Name("_viewOnly")
        public static let newline = Name("_newline")
        public static let text = Name("_text")
        public static let unknown = Name("_unknown")

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.init(rawValue: rawValue)
        }
    }
}
