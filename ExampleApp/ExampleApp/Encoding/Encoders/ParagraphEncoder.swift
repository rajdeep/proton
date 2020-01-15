//
//  ParagraphEncoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

extension JSON {
    var type: String? {
        get { return self["type"] as? String }
        set { self["type"] = newValue }
    }

    var contents: [JSON]? {
        get { return self["contents"] as? [JSON] }
        set { self["contents"] = newValue }
    }
}

struct ParagraphEncoder: EditorTextEncoding {
    func encode(name: EditorContent.Name, string: NSAttributedString) -> JSON {
        var paragraph = JSON()
        paragraph.type = name.rawValue
        if let style = string.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
            paragraph[style.key] = style.value
        }
        paragraph.contents = contentsFrom(string)
        return paragraph
    }
}

extension EditorTextEncoding where EncodedType == JSON {
    func contentsFrom(_ string: NSAttributedString) -> [JSON] {
        var contents = [JSON]()
        string.enumerateInlineContents().forEach { content in
            switch content.type {
            case .viewOnly:
                break
            case let .text(name, attributedString):
                if let encoder = JSONTransformer().textTransformers[name] {
                    let json = encoder.encode(name: name, string: attributedString)
                    contents.append(json)
                }
            case let .attachment(name, contentView, _):
                if let encodable = JSONTransformer().attachmentTransformers[name] {
                    contents.append(encodable.encode(name: name, view: contentView))
                }
            }
        }
        return contents
    }
}
