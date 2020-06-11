//
//  ListCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 28/5/20.
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

enum Indentation {
    case indent
    case outdent
}

public struct LineFormatting {
    public let indentation: CGFloat
    public let spacingBefore: CGFloat

    public init(indentation: CGFloat, spacingBefore: CGFloat) {
        self.indentation = indentation
        self.spacingBefore = spacingBefore
    }
}

public class ListCommand: EditorCommand {
    public init() { }

    public var name: CommandName {
        return CommandName("listCommand")
    }

    public var attributeValue: Any?

    public func execute(on editor: EditorView) {
        let editedRange = editor.selectedRange
        guard editedRange.length > 0 else {
            ListTextProcessor().createListItemInANewLine(editor: editor, editedRange: editedRange, indentMode: .indent, attributeValue: attributeValue)
            return
        }

        var selectedRange = editor.selectedRange
        // Adjust to span entire line range if the selection starts in the middle of the line
        if let currentLine = editor.contentLinesInRange(NSRange(location: selectedRange.location, length: 0)).first {
            selectedRange = NSRange(location: currentLine.range.location, length: selectedRange.length + (selectedRange.location - currentLine.range.location))
        }

        guard let attrValue = attributeValue else {
            let paragraphStyle = editor.paragraphStyle
            editor.addAttributes([
                .paragraphStyle: paragraphStyle
            ], at: selectedRange)
            editor.removeAttribute(.listItem, at: selectedRange)
            return
        }

        // Fix the list attribute on the trailing `\n` in previous line, if previous line has a listItem attribute applied
        if let previousLine = editor.previousContentLine(from: editor.selectedRange.location),
            let listValue = editor.attributedText.attribute(.listItem, at: previousLine.range.endLocation - 1, effectiveRange: nil),
            editor.attributedText.attribute(.listItem, at: previousLine.range.endLocation, effectiveRange: nil) == nil {
            editor.addAttribute(.listItem, value: listValue, at: NSRange(location: previousLine.range.endLocation, length: 1))
        }

        editor.attributedText.enumerateAttribute(.paragraphStyle, in: selectedRange, options: []) { (value, range, _) in
            let paraStyle = value as? NSParagraphStyle
            let mutableStyle = ListTextProcessor().updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: .indent)
            editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: range)
        }
        editor.addAttribute(.listItem, value: attrValue, at: editor.selectedRange)
        attributeValue = nil
    }

    public func execute(on editor: EditorView, attributeValue: Any?) {
        self.attributeValue = attributeValue
        execute(on: editor)
    }
}
