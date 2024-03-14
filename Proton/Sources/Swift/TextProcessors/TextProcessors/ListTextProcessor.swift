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

public enum ListMarkerDebugOption {
    case `default`
    case replace(with: String)
}

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
open class ListTextProcessor: TextProcessing {
    public let name = "listProcessor"

    typealias ContinueExecution = Bool

    public static var markerDebugOptions: ListMarkerDebugOption = .default

    // Zero width space - used for laying out the list bullet/number in an empty line.
    // This is required when using tab on a blank bullet line. Without this, layout calculations are not performed.
    static var blankLineFiller: String {
        switch markerDebugOptions {
        case .default:
            return "\u{200B}"
        case .replace(let string):
            return string
        }
    }

    /// Initializes text processor.
    public init() { }

    /// Priority of the text processor.
    public let priority = TextProcessingPriority.medium

    var executeOnDidProcess: ((EditorView) -> Void)?

    open func shouldProcess(_ editorView: EditorView, shouldProcessTextIn range: NSRange, replacementText text: String) -> Bool {
        let rangeToCheck = max(0, min(range.endLocation, editorView.contentLength) - 1)
        if editorView.contentLength > 0,
           let value = editorView.attributedText.attribute(.listItem, at: rangeToCheck, effectiveRange: nil),
           (editorView.attributedText.attribute(.paragraphStyle, at: rangeToCheck, effectiveRange: nil) as? NSParagraphStyle)?.firstLineHeadIndent ?? 0 > 0 {
            editorView.typingAttributes[.listItem] = value
        }
        return true
    }

    open func processInterrupted(editor: EditorView, at range: NSRange) { }

    open func willProcess(editor: EditorView, deletedText: NSAttributedString, insertedText: NSAttributedString, range: NSRange) { }

    open func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed {
        return false
    }

    open func didProcess(editor: EditorView) {
        guard isProcessingList(editor: editor) else { return }

        executeOnDidProcess?(editor)
        executeOnDidProcess = nil

        if let currentLine = editor.contentLinesInRange(editor.selectedRange).first,
           let rangeToReplace = currentLine.text.rangeOfCharacter(from: CharacterSet(charactersIn: ListTextProcessor.blankLineFiller)),
           currentLine.text.length > 1 {
            let adjustedRange = NSRange(location: rangeToReplace.location + currentLine.range.location, length: rangeToReplace.length)
            let proposedSelectedLocation = editor.selectedRange.location - 1
            editor.replaceCharacters(in: adjustedRange, with: NSAttributedString())
            // Resetting selected range may not be required if the replace operation results in changing that
            // automatically, i.e. in case the list item is last item in the editor and deleting the marker character
            // results in editor selected range to adjust as it happens to be outside editor content length
            if proposedSelectedLocation != editor.selectedRange.location {
                editor.selectedRange = NSRange(location: proposedSelectedLocation, length: editor.selectedRange.length)
            }
        }

//        guard editor.selectedRange.endLocation < editor.contentLength else {
//            let previousCharLocation = editor.selectedRange.previousPosition.location
//            guard previousCharLocation < editor.contentLength else { return }
        guard let previousCharacterRange = editor.selectedRange.previousCharacterRange else { return }
            let lastChar = editor.attributedText.attributedSubstring(from: previousCharacterRange)
            if lastChar.string.rangeOfCharacter(from: .newlines) != nil,
               let listAttr = lastChar.attribute(.listItem, at: 0, effectiveRange: nil) {
                let lastRange = editor.selectedRange
                var attrs = editor.typingAttributes
                attrs[.listItem] = listAttr
                let marker = NSAttributedString(string: ListTextProcessor.blankLineFiller, attributes: attrs)
                editor.replaceCharacters(in: lastRange, with: marker)
                editor.selectedRange = editor.selectedRange.nextPosition
            }
//            return
//        }
//        let lastChar = editor.attributedText.substring(from: NSRange(location: editor.selectedRange.location, length: 1))
//        if lastChar == ListTextProcessor.blankLineFiller {
//            editor.selectedRange = editor.selectedRange.nextPosition
//        }
        editor.typingAttributes[.skipNextListMarker] = nil
    }
    
    open func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange)  {
        guard editedRange != .zero,
              isProcessingList(editor: editor) else { return }

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

    private func isProcessingList(editor: EditorView) -> Bool {
        guard editor.selectedRange != .zero else { return false }
        if editor.selectedRange.length == 0 {
            return editor.attributedText.hasAttribute(.listItem, at: editor.selectedRange.location - 1)
        } else {
            return editor.attributedText.hasAttribute(.listItem, at: editor.selectedRange.location)
        }
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

    private func updateListItemIfRequired(editor: EditorView, editedRange: NSRange, indentMode: Indentation, attributeValue: Any?) {
        let lines = editor.contentLinesInRange(editedRange)

        for line in lines {
            if line.text.length == 0 || line.text.attribute(.listItem, at: 0, effectiveRange: nil) == nil {
                var paraStyle: NSParagraphStyle? = nil
                var range = line.range
                if let prevCharRange = line.range.previousCharacterRange,
                   prevCharRange.isValidIn(editor.textInput) {
                    paraStyle = editor.attributedText.attribute(.paragraphStyle, at: prevCharRange.location, effectiveRange: nil) as? NSParagraphStyle
                    range = prevCharRange
                }

                notifyIndentationChange(editor: editor, paraStyle: paraStyle, lineRange: range, indentMode: indentMode)
                createListItemInANewLine(editor: editor, editedRange: line.range, indentMode: indentMode, attributeValue: attributeValue)
                continue
            }

            let paraStyle = line.text.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
            let mutableStyle = updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: indentMode, defaultParaStyle: editor.paragraphStyle)

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

            notifyIndentationChange(editor: editor, paraStyle: paraStyle, lineRange: line.range, indentMode: indentMode)

            editor.addAttribute(.paragraphStyle, value: mutableStyle ?? editor.paragraphStyle, at: line.range)

            // Remove listItem attribute if indented all the way back
            if mutableStyle?.firstLineHeadIndent == 0 {
                if let previousCharacterRange = line.range.previousCharacterRange {
                    editor.removeAttribute(.listItem, at: previousCharacterRange)
                }
                editor.replaceCharacters(in: NSRange(location: line.range.location, length: 2), with: "")
                editor.typingAttributes[.paragraphStyle] = editor.paragraphStyle
                // remove list attribute from new line char in the previous line
                if let previousLine = previousLine {
                    editor.removeAttribute(.listItem, at: NSRange(location: previousLine.range.endLocation, length: 1))
                }
            }


//            indentChildLists(editor: editor, editedRange: line.range, originalParaStyle: paraStyle, indentMode: indentMode)
        }
    }

    private func notifyIndentationChange(editor: EditorView, paraStyle: NSParagraphStyle?, lineRange: NSRange, indentMode: Indentation) {
        let currentLevel = Int((paraStyle ?? editor.paragraphStyle).firstLineHeadIndent/editor.listLineFormatting.indentation)
        var latestAttributeValueAtProposedLevel: Any?
        let newLevel = CGFloat(indentMode == .indent ? currentLevel + 1 : currentLevel - 1) * editor.listLineFormatting.indentation
        editor.attributedText.enumerateAttribute(.listItem, in: NSRange(location: 0, length: lineRange.endLocation), options: [.reverse, .longestEffectiveRangeNotRequired]) { attrValue, range, stop in
            if let paragraphStyle = editor.attributedText.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle,
               paragraphStyle.firstLineHeadIndent == newLevel {
                latestAttributeValueAtProposedLevel = attrValue
                stop.pointee = true
            }
        }
        editor.listFormattingProvider?.willChangeListIndentation(editor: editor, range: lineRange, currentLevel: currentLevel, indentMode: indentMode, latestAttributeValueAtProposedLevel: latestAttributeValueAtProposedLevel)
    }

    private func indentChildLists(editor: EditorView, editedRange: NSRange, originalParaStyle: NSParagraphStyle?, indentMode: Indentation) {
        var subListRange = NSRange.zero
        guard let nextLine = editor.nextContentLine(from: editedRange.nextPosition.location),
              let originalParaStyle = originalParaStyle,
              editor.attributedText.attribute(.listItem, at: nextLine.range.location, longestEffectiveRange: &subListRange, in: NSRange(location: nextLine.range.location, length: editor.contentLength - nextLine.range.location)) != nil
        else { return }

        editor.attributedText.enumerateAttribute(.paragraphStyle, in: subListRange, options: []) { value, range, stop in
            if let style = value as? NSParagraphStyle {
                if style.firstLineHeadIndent >= originalParaStyle.firstLineHeadIndent + editor.listLineFormatting.indentation {
                    let mutableStyle = updatedParagraphStyle(paraStyle: style, listLineFormatting: editor.listLineFormatting, indentMode: indentMode, defaultParaStyle: editor.paragraphStyle)
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
        let updatedStyle = updatedParagraphStyle(paraStyle: paraStyle, listLineFormatting: editor.listLineFormatting, indentMode: indentMode, defaultParaStyle: editor.paragraphStyle)
        attrs[.paragraphStyle] = updatedStyle
        attrs[.listItem] = updatedStyle?.firstLineHeadIndent ?? 0 > 0.0 ? listAttributeValue : nil
        let marker = NSAttributedString(string: ListTextProcessor.blankLineFiller, attributes: attrs)
        editor.replaceCharacters(in: editedRange, with: marker)
        editor.selectedRange = editedRange.nextPosition
    }

    func updatedParagraphStyle(paraStyle: NSParagraphStyle?, listLineFormatting: LineFormatting, indentMode: Indentation, defaultParaStyle: NSParagraphStyle) -> NSParagraphStyle? {
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
        if let spacingAfter = listLineFormatting.spacingAfter {
            mutableStyle?.paragraphSpacing = spacingAfter
        }

        if mutableStyle?.firstLineHeadIndent == 0, indentMode == .outdent {
            mutableStyle?.paragraphSpacingBefore = defaultParaStyle.lineFormatting.spacingBefore
            mutableStyle?.paragraphSpacing = defaultParaStyle.lineFormatting.spacingAfter ?? 0
        }

        return mutableStyle
    }
}
