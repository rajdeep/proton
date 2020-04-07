//
//  ParagraphEncoder.swift
//  ExampleApp
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

import Proton

extension JSON {
    var type: String? {
        get { self["type"] as? String }
        set { self["type"] = newValue }
    }

    var contents: [JSON]? {
        get { self["contents"] as? [JSON] }
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
                if let encoder = JSONEncoder().textEncoders[name] {
                    let json = encoder.encode(name: name, string: attributedString)
                    contents.append(json)
                }
            case let .attachment(name, _, contentView, _):
                if let encodable = JSONEncoder().attachmentEncoders[name] {
                    contents.append(encodable.encode(name: name, view: contentView))
                }
            }
        }
        return contents
    }
}
