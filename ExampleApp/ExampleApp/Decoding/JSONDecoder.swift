//
//  JSONDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 17/1/20.
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

struct EditorDecodingContext {
    var name: String
}

struct EditorContentJSONDecoder: EditorContentDecoding {
    static let contentDecoders: [EditorContent.Name: AnyEditorContentDecoding<JSON, EditorDecodingContext?>] = [
        EditorContent.Name.paragraph: AnyEditorContentDecoding(ParagraphDecoder()),
        EditorContent.Name.text: AnyEditorContentDecoding(TextDecoder()),
        EditorContent.Name("panel"): AnyEditorContentDecoding(PanelDecoder())
    ]

    static let attributeDecoders: [String: AnyAttributedStringAttributeDecoding<JSON>] = [
        "font": AnyAttributedStringAttributeDecoding(UIFontDecoder()),
        "style": AnyAttributedStringAttributeDecoding(ParagraphStyleDecoder()),
    ]

    func decode(mode: EditorContentMode, maxSize: CGSize, value: JSON, context: EditorDecodingContext?) -> NSAttributedString {
        let string = NSMutableAttributedString()
        for content in value.contents ?? [] {
            if let type = content.type {
                let typeName = EditorContent.Name(type)
                let decoder = EditorContentJSONDecoder.contentDecoders[typeName]
                let contentValue = decoder?.decode(mode: mode, maxSize: maxSize, value: content, context: context) ?? NSAttributedString()
                string.append(contentValue)
            }
        }
        return string
    }
}
