//
//  ListTextProcessor.swift
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

/// Text process capable of processing keyboard inputs specific to lists. `ListTextProcessor` only works after a range of text
/// has been converted to list using `ListCommand`.
///
/// Supports the following inputs:
/// 1. Enter: Creates a new list item at the same level as the current one. Using Enter twice in a row at the last list item exits list.
/// When used twice in a row in the middle of a list, it only creates empty list items and does not exit list.
/// 2. Shift-Enter: Adds a soft line break i.e. does not create a new list item but moves to next line.
/// 3. Tab: Indents the current level to next indentation level. A level may only be indented 1 level deeper than previous level.
/// First level items cannot be indented.
/// 4. Shift-Tab: Outdents text in list by one level each time. Using this on first level exits the list formatting for given text.
public class ListTextProcessor: TextProcessing {
    public let name = "listProcessor"

    // Zero width space - used for laying out the list bullet/number in an empty line.
    // This is required when using tab on a blank bullet line. Without this, layout calculations are not performed.
    static let blankLineFiller = "\u{200B}"

    /// Initializes text processor.
    public init() { }

    /// Priority of the text processor.
    public let priority = TextProcessingPriority.medium

    var executeOnDidProcess: ((EditorView) -> Void)?

    public func shouldProcess(_ editorView: EditorView, shouldProcessTextIn range: NSRange, replacementText text: String) -> Bool {
        let rangeToCheck = max(0, min(range.endLocation, editorView.contentLength) - 1)
        if editorView.contentLength > 0,
           let value = editorView.attributedText.attribute(.listItem, at: rangeToCheck, effectiveRange: nil),
           (editorView.attributedText.attribute(.paragraphStyle, at: rangeToCheck, effectiveRange: nil) as? NSParagraphStyle)?.firstLineHeadIndent ?? 0 > 0 {
            editorView.typingAttributes[.listItem] = value
        }
        return true
    }

    public func processInterrupted(editor: EditorView, at range: NSRange) { }

    public func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed {
        return false
    }

    public func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange)  {
        guard editedRange != .zero else { return }
        switch key {
        case .tab:
            // Indent only if previous character is a listItem
            guard editedRange.location > 0,
                  let attributeValue = editor.attributedText.attribute(.listItem, at: editedRange.location - 1, effectiveRange: nil)
            else { return }
            
            let indentMode: Indentation  = (modifierFlags == .shift) ? .outdent : .indent
            updateListItemIfRequired(editor: editor, editedRange: editedRange, indentMode: indentMode, attributeValue: attributeValue)
        case .enter:
            let location = min(editedRange.location, editor.contentLength - 1)
            guard location >= 0,
                  editor.contentLength > 0
            else { return }
            
            let attrs = editor.attributedText.attributes(at: location, effectiveRange: nil)
            if attrs[.listItem] != nil {
                if modifierFlags == .shift {
                    handleShiftReturn(editor: editor, editedRange: editedRange, attrs: attrs)
                } else {
                    exitListsIfRequired(editor: editor, editedRange: editedRange)
                }
            }

        case .backspace:
            let attributedText = editor.attributedText
            guard editedRange.location > 0,
                  attributedText.substring(from: editedRange) == ListTextProcessor.blankLineFiller,
                  attributedText.attribute(.listItem, at: editedRange.location, effectiveRange: nil) != nil,
                  attributedText.substring(from: NSRange(location: editedRange.location - 1, length: 1)) == "\n"
            else { return }
            
            editor.deleteBackward()
            
        default:
            break
        }
    }

    func exitList(editor: EditorView) {
        guard editor.isEmpty == false,
            let currentContentLineRange = editor.contentLinesInRange(editor.selectedRange).first?.range,
              editor.attributedText.attribute(
                  .listItem,
                  at: max(0, currentContentLineRange.endLocation - 1),
                  effectiveRange: nil) != nil
        else { return }

        terminateList(editor: editor, editedRange: currentContentLineRange)
    }

    private func terminateList(editor: EditorView, editedRange: NSRange) {
        editor.typingAttributes[.listItem] = nil
        self.updateListItemIfRequired(
            editor: editor,
            editedRange: editedRange,
            indentMode: .outdent,
            attributeValue: nil
        )
        let rangeToReplace = NSRange(location: editedRange.location + 1, length: 1)
        editor.replaceCharacters(in: rangeToReplace, with: "")
        if editor.selectedRange.endLocation >= rangeToReplace.endLocation {
            editor.selectedRange = NSRange(location: editor.selectedRange.location - 1, length: 0)
        }
    }

    private func handleShiftReturn(editor: EditorView, editedRange: NSRange, attrs: [NSAttributedString.Key: Any]) {
        var attributes = attrs
        attributes[.skipNextListMarker] = 1
        let newLineRange = NSRange(location: editedRange.location, length: 0)
        let newLine = NSAttributedString(string: "\n", attributes: attributes)
        editor.replaceCharacters(in: newLineRange, with: newLine)
        editor.selectedRange = editedRange.nextPosition
    }

    private func exitListsIfRequired(editor: EditorView, editedRange: NSRange) {
        guard let currentLine = editor.contentLinesInRange(editedRange).first,
              let previousLine = editor.previousContentLine(from: currentLine.range.location)
        else { return }

        if let nextLine = editor.nextContentLine(from: currentLine.range.location),
           nextLine.range.endLocation < editor.contentLength - 1 {
            let attributedText = editor.attributedText
            var isNotNewLineCharacter: Bool {
                let nextLineText = attributedText.substring(from: NSRange(location: nextLine.range.location, length: 1))
                return nextLineText != "\n"
            }
            var isFirstLevelListItem: Bool {
                guard let paraStyle = attributedText.attribute(.paragraphStyle, at: nextLine.range.location, effectiveRange: nil) as? NSParagraphStyle else {
                    return false
                }
                return paraStyle.firstLineHeadIndent / editor.listLineFormatting.indentation == 1
            }
            let hasListItemAttribute = attributedText.attribute(.listItem, at: nextLine.range.location, effectiveRange: nil) != nil
            if hasListItemAttribute, (isNotNewLineCharacter || !isFirstLevelListItem) {
                return
            }
        }

        var attributeValue = editor.typingAttributes[.listItem]
        if previousLine.text.length > 0 {
            attributeValue = previousLine.text.attribute(.listItem, at: 0, effectiveRange: nil)
        }

        if (currentLine.text.length == 0 || currentLine.text.string == ListTextProcessor.blankLineFiller),
           attributeValue != nil {
            executeOnDidProcess = { [weak self] editor in
                self?.terminateList(editor: editor, editedRange: currentLine.range)
            }
        }
    }

    public func didProcess(editor: EditorView) {
        executeOnDidProcess?(editor)
        executeOnDidProcess = nil
        guard editor.selectedRange.endLocation < editor.contentLength else { return }
        let lastChar = editor.attributedText.substring(from: NSRange(location: editor.selectedRange.location, length: 1))
        if lastChar == ListTextProcessor.blankLineFiller {
            editor.selectedRange = editor.selectedRange.nextPosition
        }
        editor.typingAttributes[.skipNextListMarker] = nil
    }

    private func updateListItemIfRequired(editor: EditorView, editedRange: NSRange, indentMode: Indentation, attributeValue: Any?) {
        let lines = editor.contentLinesInRange(editedRange)

        for line in lines {
            if line.text.length == 0 || line.text.attribute(.listItem, at: 0, effectiveRange: nil) == nil {
                createListItemInANewLine(editor: editor, editedRange: line.range, indentMode: indentMode, attributeValue: attributeValue)
                continue
            }

            let paraStyle = line.text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            let mutableStyle = updatedParagraphStyle(paraStyle: paraStyle,  listLineFormatting: editor.listLineFormatting, indentMode: indentMode)

            let previousLine = editor.previousContentLine(from: line.range.location)
            if let previousLine = previousLine,
               previousLine.text.length > 0 {
                let previousStyle = previousLine.text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
                guard mutableStyle?.firstLineHeadIndent ?? 0 <= (previousStyle?.firstLineHeadIndent ?? 0) + editor.listLineFormatting.indentation else {
                    return
                }
            }
            // exit indentation if the resulting indentation is more than 1 level indent points
            else if (mutableStyle?.firstLineHeadIndent ?? 0) > editor.listLineFormatting.indentation {
                return
            }

            editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: line.range)

            // Remove listItem attribute if indented all the way back
            if mutableStyle?.firstLineHeadIndent == 0 {
                editor.removeAttribute(.listItem, at: line.range)
                // remove list attribute from new line char in the previous line
                if let previousLine = previousLine {
                    editor.removeAttribute(.listItem, at: NSRange(location: previousLine.range.endLocation, length: 1))
                }
            }
            indentChildLists(editor: editor, editedRange: line.range, originalParaStyle: paraStyle, indentMode: indentMode)
        }
    }

    private func indentChildLists(editor: EditorView, editedRange: NSRange, originalParaStyle: NSParagraphStyle?, indentMode: Indentation) {
        var subListRange = NSRange.zero
        guard let nextLine = editor.nextContentLine(from: editedRange.location),
              let originalParaStyle = originalParaStyle,
              editor.attributedText.attribute(.listItem, at: nextLine.range.location, longestEffectiveRange: &subListRange, in: NSRange(location: nextLine.range.location, length: editor.contentLength - nextLine.range.location)) != nil
        else { return }

        editor.attributedText.enumerateAttribute(.paragraphStyle, in: subListRange, options: []) { value, range, stop in
            if let style = value as? NSParagraphStyle {
                if style.firstLineHeadIndent >= originalParaStyle.firstLineHeadIndent + editor.listLineFormatting.indentation {
                    let mutableStyle = updatedParagraphStyle(paraStyle: style, listLineFormatting: editor.listLineFormatting, indentMode: indentMode)
                    editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: range)
                } else {
                    stop.pointee = true
                }
            }
        }
    }

    func createListItemInANewLine(editor: EditorView, editedRange: NSRange, indentMode: Indentation, attributeValue: Any?) {
        var listAttributeValue = attributeValue
        if listAttributeValue == nil, editedRange.location > 0 {
            listAttributeValue = editor.attributedText.attribute(.listItem, at: editedRange.location - 1, effectiveRange: nil)
        }
        listAttributeValue = listAttributeValue ?? "listItemValue" // default value in case no other value can be obtained.

        var attrs = editor.typingAttributes
        let paraStyle = attrs[.paragraphStyle] as? NSParagraphStyle
        let updatedStyle = updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: indentMode)
        attrs[.paragraphStyle] = updatedStyle
        attrs[.listItem] = updatedStyle?.firstLineHeadIndent ?? 0 > 0.0 ? listAttributeValue : nil
        let marker = NSAttributedString(string: ListTextProcessor.blankLineFiller, attributes: attrs)
        editor.replaceCharacters(in: editedRange, with: marker)
        editor.selectedRange = editedRange.nextPosition
    }

    func updatedParagraphStyle(paraStyle: NSParagraphStyle?, listLineFormatting: LineFormatting, indentMode: Indentation) -> NSParagraphStyle? {
        let mutableStyle = paraStyle?.mutableCopy() as? NSMutableParagraphStyle
        let indent = listLineFormatting.indentation
        if indentMode == .indent {
            mutableStyle?.firstLineHeadIndent += indent
            mutableStyle?.headIndent = mutableStyle?.firstLineHeadIndent ?? 0
        } else {
            mutableStyle?.firstLineHeadIndent -= indent
            mutableStyle?.headIndent = mutableStyle?.firstLineHeadIndent ?? 0
        }
        mutableStyle?.paragraphSpacingBefore = listLineFormatting.spacingBefore

        if mutableStyle?.firstLineHeadIndent == 0, indentMode == .outdent {
            mutableStyle?.paragraphSpacingBefore = paraStyle?.lineFormatting.spacingBefore ?? 0
        }

        return mutableStyle
    }
}
