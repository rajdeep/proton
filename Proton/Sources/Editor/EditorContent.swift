//
//  EditorContent.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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
    case attachment(name: EditorContent.Name, contentView: UIView, type: AttachmentType)
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
        enclosingRange = nil
    }

    init(type: EditorContentType, enclosingRange: NSRange) {
        self.type = type
        self.enclosingRange = enclosingRange
    }
}

public extension EditorContent {
    struct Name: Hashable, Equatable, RawRepresentable {
        public var rawValue: String

        public static let paragraph = Name("paragraph")
        public static let viewOnly = Name("viewOnly")
        public static let newline = Name("newline")
        public static let text = Name("text")
        public static let unknown = Name("unknown")

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
