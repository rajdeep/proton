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

public class ListTextProcessor: TextProcessing {
    public let name = "listProcessor"

    // Zero width space - used for laying out the list bullet/number in an empty line.
    // This is required when using tab on a blank bullet line. Without this, layout calculations are not performed.
    private let blankLineFiller = "\u{200B}"

    public init() { }
    public let priority = TextProcessingPriority.medium

    var executeOnDidProcess: ((EditorView) -> Void)?

    public func shouldProcess(_ editorView: EditorView, shouldProcessTextIn range: NSRange, replacementText text: String) -> Bool {
        let rangeToCheck = max(0, range.endLocation - 1)
        if editorView.contentLength > 0,
            editorView.attributedText.attribute(.listItem, at: rangeToCheck, effectiveRange: nil) != nil,
            (editorView.attributedText.attribute(.paragraphStyle, at: rangeToCheck, effectiveRange: nil) as? NSParagraphStyle)?.firstLineHeadIndent ?? 0 > 0 {
            editorView.typingAttributes[.listItem] = 1
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
                let attributeValue = editor.attributedText.attribute(.listItem, at: editedRange.location - 1, effectiveRange: nil) else {
                    return
            }
            let indentMode: Indentation  = (modifierFlags == .shift) ? .outdent : .indent
            updateListItemIfRequired(editor: editor, editedRange: editedRange, indentMode: indentMode, attributeValue: attributeValue)
        case .enter:
            let attrs = editor.attributedText.attributes(at: editedRange.location, effectiveRange: nil)
            if attrs[.listItem] != nil {
                exitListsIfRequired(editor: editor, editedRange: editedRange)
            }
        case .backspace:
            let text = editor.attributedText.attributedSubstring(from: editedRange)
            guard editedRange.location > 0,
                text.string == blankLineFiller,
                text.attribute(.listItem, at: 0, effectiveRange: nil) != nil,
                editor.attributedText.attributedSubstring(from: NSRange(location: editedRange.location - 1, length: 1)).string == "\n" else {
                return
            }
            editor.deleteBackward()
        }
    }

    private func exitListsIfRequired(editor: EditorView, editedRange: NSRange) {
        guard let currentLine = editor.contentLinesInRange(editedRange).first,
            let previousLine = editor.previousContentLine(from: currentLine.range.location) else { return }

        if let nextLine = editor.nextContentLine(from: currentLine.range.location),
            nextLine.range.endLocation < editor.contentLength - 1 {
            let nextLineText = editor.attributedText.attributedSubstring(from: NSRange(location: nextLine.range.location, length: 1))
            if nextLineText.attribute(.listItem, at: 0, effectiveRange: nil) != nil {
                return
            }
        }

        var attributeValue = editor.typingAttributes[.listItem]
        if previousLine.text.length > 0 {
            attributeValue = previousLine.text.attribute(.listItem, at: 0, effectiveRange: nil)
        }

        if (currentLine.text.length == 0 || currentLine.text.string == blankLineFiller),
            attributeValue != nil {
            executeOnDidProcess = { [weak self] editor in
                self?.updateListItemIfRequired(editor: editor, editedRange: currentLine.range, indentMode: .outdent, attributeValue: attributeValue)
                editor.replaceCharacters(in: NSRange(location: currentLine.range.location + 1, length: 1), with: "")
            }
        }
    }

    public func didProcess(editor: EditorView) {
        executeOnDidProcess?(editor)
        executeOnDidProcess = nil
        guard editor.selectedRange.endLocation < editor.contentLength else { return }
        let lastChar = editor.attributedText.attributedSubstring(from: NSRange(location: editor.selectedRange.location, length: 1))
        if lastChar.string == blankLineFiller {
            editor.selectedRange = editor.selectedRange.nextPosition
        }
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
            editor.attributedText.attribute(.listItem, at: nextLine.range.location, longestEffectiveRange: &subListRange, in: NSRange(location: nextLine.range.location, length: editor.contentLength - nextLine.range.location)) != nil  else { return }

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
        var attrs = editor.typingAttributes
        let paraStyle = attrs[.paragraphStyle] as? NSParagraphStyle
        let updatedStyle = updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: indentMode)
        attrs[.paragraphStyle] = updatedStyle
        attrs[.listItem] = updatedStyle?.firstLineHeadIndent ?? 0 > 0.0 ? attributeValue ?? 1 : nil
        let marker = NSAttributedString(string: blankLineFiller, attributes: attrs)
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
