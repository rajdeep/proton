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

    public func execute(on editor: EditorView) {
        let editedRange = editor.selectedRange
        guard editedRange.length > 0 else {
            ListTextProcessor().createListItemInANewLine(editor: editor, editedRange: editedRange, indentMode: .indent)
            return
        }

        editor.attributedText.enumerateAttribute(.paragraphStyle, in: editor.selectedRange, options: []) { (value, range, _) in
            let paraStyle = value as? NSParagraphStyle
            let mutableStyle = ListTextProcessor().updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: .indent)
            editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: range)
        }
        editor.addAttribute(.listItem, value: true, at: editor.selectedRange)
    }
}
