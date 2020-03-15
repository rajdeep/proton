//
//  JSONDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 17/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

struct EditorContentJSONDecoder: EditorContentDecoding {
    static let contentDecoders: [EditorContent.Name: AnyEditorContentDecoding<JSON>] = [
        EditorContent.Name.paragraph: AnyEditorContentDecoding(ParagraphDecoder()),
        EditorContent.Name.text: AnyEditorContentDecoding(TextDecoder()),
        EditorContent.Name("panel"): AnyEditorContentDecoding(PanelDecoder()),
    ]

    static let attributeDecoders: [String: AnyAttributedStringAttributeDecoding<JSON>] = [
        "font": AnyAttributedStringAttributeDecoding(UIFontDecoder()),
        "style": AnyAttributedStringAttributeDecoding(ParagraphStyleDecoder()),
    ]

    func decode(mode: EditorContentMode, maxSize: CGSize, value: JSON) -> NSAttributedString {
        let string = NSMutableAttributedString()
        for content in value.contents ?? [] {
            if let type = content.type {
                let typeName = EditorContent.Name(type)
                let decoder = EditorContentJSONDecoder.contentDecoders[typeName]
                let contentValue = decoder?.decode(mode: mode, maxSize: maxSize, value: content)
                    ?? NSAttributedString()
                string.append(contentValue)
            }
        }
        return string
    }
}
