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

extension String {
    var isChecklist: Bool {
        return self == "listItemCheckList" || self == "listItemSelectedChecklist"
    }
}

public enum Indentation {
    case indent
    case outdent
}

/// Describes the formatting of a line of text. While general purpose in nature, this is
/// used by `EditorListFormattingProvider` for providing formatting for lists.
public struct LineFormatting {

    /// Indentation of line
    public let indentation: CGFloat

    /// Vertical spacing before the line
    public let spacingBefore: CGFloat

    /// Initializes
    /// - Parameters:
    ///   - indentation: Indentation for each line of text
    ///   - spacingBefore: Vertical spacing before line of text
    public init(indentation: CGFloat, spacingBefore: CGFloat) {
        self.indentation = indentation
        self.spacingBefore = spacingBefore
    }
}

/// Command that can be used to toggle list attributes of selected range of text.
/// If the length of selected range of text is 0, the attributes are applied on the current line of text.
public class ListCommand: EditorCommand {
    public init() { }

    /// Name of the command
    public var name: CommandName {
        return CommandName("listCommand")
    }

    /// Value to be set for attribute `.listItem` when applying to a range of text.
    /// This value is returned back by `ListFormattingProvider` when querying list marker for a given index.
    /// This may be used to store info that helps generate appropriate markers for e.g. storing context related
    /// to bullet vs ordered lists.
    /// - Note:
    /// When set to nil before running `execute`, it removes list formatting from the selected range of text.
    public var attributeValue: Any?

    /// Executes the command with value of `attributeValue` for `.listItem` attribute. If the `attributeValue` is nil, executing
    /// removed list formatting from the selected range of text.
    /// - Parameter editor: Editor to execute the command on.
    public func execute(on editor: EditorView) {
        var selectedRange = editor.selectedRange
        // Adjust to span entire line range if the selection starts in the middle of the line
        if let currentLine = editor.contentLinesInRange(NSRange(location: selectedRange.location, length: 0)).first,
           currentLine.range.length > 0 {
            let location = currentLine.range.location
            var length = max(currentLine.range.length, selectedRange.length + (selectedRange.location - currentLine.range.location))
            let range = NSRange(location: location, length: length)
            if editor.contentLength > range.endLocation,
               editor.attributedText.substring(from: NSRange(location: range.endLocation, length: 1)) == "\n" {
                length += 1
            }
            selectedRange = NSRange(location: location, length: length)
        }
        
        guard selectedRange.length > 0 else {
            if editor.isEmpty ||
                editor.attributedText.attribute(.listItem, at: max(0, editor.selectedRange.location - 1), effectiveRange: nil) == nil {
                ListTextProcessor().createListItemInANewLine(editor: editor, editedRange: selectedRange, indentMode: .indent, attributeValue: attributeValue)
            } else if let listItem = editor.attributedText.attribute(.listItem, at: max(0, editor.selectedRange.location - 1), effectiveRange: nil) as? String, let attributeValue = attributeValue as? String, listItem != attributeValue {
                let listItemValue = editor.attributedText.attribute(.listItemValue, at: max(0, editor.selectedRange.location - 1), effectiveRange: nil) as? String
                
                if listItem.isChecklist || attributeValue.isChecklist {
                    ListTextProcessor().createListItemInANewLine(editor: editor, editedRange: selectedRange, indentMode: .indent, attributeValue: attributeValue)
                } else {
                    editor.attributedText.enumerateAttribute(.listItemValue, in: editor.attributedText.fullRange) { value, range, stop in
                        guard let value = value as? String else { return }
                        if value == listItemValue {
                            editor.addAttribute(.listItem, value: attributeValue, at: range)
                        }
                    }
                }
            } else {
                ListTextProcessor().exitList(editor: editor)
            }
            return
        }

        guard let attrValue = attributeValue else {
            let paragraphStyle = editor.paragraphStyle
            editor.addAttributes([
                .paragraphStyle: paragraphStyle
            ], at: selectedRange)
            editor.removeAttribute(.listItem, at: selectedRange)
            editor.removeAttribute(.listItemValue, at: selectedRange)
            editor.typingAttributes[.listItem] = nil
            editor.typingAttributes[.listItemValue] = nil
            return
        }
        
        var flag = false
        if let line = editor.currentLayoutLine, let listItem = editor.attributedText.attribute(.listItem, at: line.range.location, effectiveRange: nil) as? String {
             if listItem == "listItemSelectedChecklist" {
                 editor.typingAttributes[.strikethroughStyle] = nil
                 editor.typingAttributes[.foregroundColor] = editor.textColor
             }
             
             flag = listItem.isChecklist || ((attrValue as? String)?.isChecklist ?? false)
        }
        
        var listItemValue = editor.attributedText.attribute(.listItemValue, at: selectedRange.location, effectiveRange: nil) as? String
        if listItemValue == nil {
            if let prevLine = editor.previousContentLine(from: selectedRange.location),
               let v = getListItemValue(from: prevLine, editor: editor) {
                listItemValue = v
            } else if let nextLine = editor.nextContentLine(from: selectedRange.location),
                      let v = getListItemValue(from: nextLine, editor: editor) {
                listItemValue = v
            }
        }
        
        listItemValue = listItemValue ?? UUID().uuidString
        
        if !flag {
            editor.attributedText.enumerateAttribute(.listItemValue, in: editor.attributedText.fullRange) { value, range, stop in
                guard let value = value as? String else { return }
                if value == listItemValue {
                    self.handle(on: editor, range: range, attrValue: attrValue)
                }
            }
        }
        handle(on: editor, range: selectedRange, attrValue: attrValue)
        editor.addAttribute(.listItemValue, value: listItemValue, at: selectedRange)
        editor.typingAttributes[.listItem] = attrValue
        if !flag {
            editor.typingAttributes[.listItemValue] = listItemValue
        }
        
        attributeValue = nil
    }
    
    private func getListItemValue(from line: EditorLine, editor: EditorView) -> String? {
        guard let listItem = editor.attributedText.attribute(.listItem, at: line.range.location, effectiveRange: nil) as? String,
           let attrValue = attributeValue as? String,
           listItem == attrValue else {
            return nil
        }
        return editor.attributedText.attribute(.listItemValue, at: line.range.location, effectiveRange: nil) as? String
    }
    
    func handle(on editor: EditorView, range: NSRange, attrValue: Any) {
        if let previousLine = editor.previousContentLine(from: range.location),
           let listValue = editor.attributedText.attribute(.listItem, at: previousLine.range.endLocation - 1, effectiveRange: nil),
           editor.attributedText.attribute(.listItem, at: previousLine.range.endLocation, effectiveRange: nil) == nil {
            if let listItemValue = editor.attributedText.attribute(.listItemValue, at: previousLine.range.endLocation - 1, effectiveRange: nil) as? String,
               editor.attributedText.attribute(.listItemValue, at: previousLine.range.endLocation, effectiveRange: nil) == nil {
                editor.addAttribute(.listItemValue, value: listItemValue, at: NSRange(location: previousLine.range.endLocation, length: 1))
            }
            editor.addAttribute(.listItem, value: listValue, at: NSRange(location: previousLine.range.endLocation, length: 1))
        }
        editor.attributedText.enumerateAttribute(.paragraphStyle, in: range, options: []) { (value, range, _) in
            let paraStyle = value as? NSParagraphStyle
            let mutableStyle = ListTextProcessor().updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: .indent)
            editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: range)
        }
        
        editor.attributedText.enumerateAttribute(.listItem, in: range) { value, range, stop in
            guard let value = value as? String, value == "listItemSelectedChecklist" else { return }
            editor.removeAttribute(.strikethroughStyle, at: range)
            editor.addAttribute(.foregroundColor, value: editor.textColor, at: range)
        }
        editor.addAttribute(.listItem, value: attrValue, at: range)
    }

    /// Executes the command with value of `attributeValue` for `.listItem` attribute.
    /// - Parameters:
    ///   - editor: Editor to execute the command on.
    ///   - attributeValue: Value of `.listItem` attribute. Use nil to remove list formatting.
    public func execute(on editor: EditorView, attributeValue: Any?) {
        editor.attributedText.enumerateAttribute(.listItem, in: editor.attributedText.fullRange) { value, range, stop in
            guard let value = value as? String, value.isChecklist else { return }
            editor.removeAttribute(.listItemValue, at: range)
        }
        
        self.attributeValue = attributeValue
        execute(on: editor)
    }
}
