//
//  EditorContent.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

enum EditorContentType {
    case text(name: EditorContent.Name, attributedString: NSAttributedString)
    case viewOnly
}

struct EditorContent {
    let type: EditorContentType
    let enclosingRange: NSRange? //private set/public get

    init(type: EditorContentType) {
        self.type = type
        self.enclosingRange = nil
    }

    init(type: EditorContentType, enclosingRange: NSRange) {
        self.type = type
        self.enclosingRange = enclosingRange
    }
}

extension EditorContent {
    struct Name: Hashable, Equatable, RawRepresentable {
        var rawValue: String

        static let paragraph = Name("paragraph")
        static let viewOnly = Name("viewOnly")
        static let text = Name("text")
        static let unknown = Name("unknown")

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }
}
