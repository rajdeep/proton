//
//  AttributesToggleCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 23/7/21.
//  Copyright © 2021 Rajdeep Kwatra. All rights reserved.
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

/// Editor command that toggles given attributes in selected range in the Editor.
public class AttributesToggleCommand: EditorCommand {
    public let attributes: [NSAttributedString.Key: Any]

    public let name: CommandName

    public init(name: CommandName, attributes: [NSAttributedString.Key: Any]) {
        self.name = name
        self.attributes = attributes
    }

    public func execute(on editor: EditorView) {
        let selectedText = editor.selectedText
        if editor.isEmpty || editor.selectedRange == .zero || selectedText.length == 0 {
            attributes.forEach { attribute in
                if editor.typingAttributes[attribute.key] == nil {
                    editor.typingAttributes[attribute.key] = attribute.value
                } else {
                    var typingAttributes = editor.typingAttributes
                    typingAttributes[attribute.key] = nil
                    editor.typingAttributes = typingAttributes
                }
            }
            return
        }

        attributes.forEach { attribute in
            editor.attributedText.enumerateAttribute(attribute.key, in: editor.selectedRange, options: .longestEffectiveRangeNotRequired) { attrValue, range, _ in
                if attrValue == nil {
                    editor.addAttribute(attribute.key, value: attribute.value, at: range)
                } else {
                    editor.removeAttribute(attribute.key, at: range)
                }
            }
        }
    }
}
