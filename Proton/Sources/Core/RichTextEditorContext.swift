//
//  RichTextViewContext.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 7/1/20.
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
import CoreServices

class RichTextEditorContext: RichTextViewContext {
    static let `default` = RichTextEditorContext()

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard textView.delegate === self else { return }

        activeTextView = textView as? RichTextView
        guard let richTextView = activeTextView else { return }
        activeTextView?.richTextViewDelegate?.richTextView(richTextView, didReceiveFocusAt: textView.selectedRange)

        let range = textView.selectedRange
        var attributes = richTextView.typingAttributes
        let contentType = attributes[.blockContentType] as? EditorContent.Name ?? .unknown
        attributes[.blockContentType] = nil
        richTextView.richTextViewDelegate?.richTextView(richTextView, didChangeSelection: range, attributes: attributes, contentType: contentType)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard textView.delegate === self else { return }

        defer {
            activeTextView = nil
        }
        guard let richTextView = activeTextView else { return }
        activeTextView?.richTextViewDelegate?.richTextView(richTextView, didLoseFocusFrom: textView.selectedRange)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard textView.delegate === self else { return true }

        guard let richTextView = activeTextView else { return true }

        // if backspace
        var handled = false
        if text.isEmpty {
            richTextView.richTextViewDelegate?.richTextView(richTextView, didReceiveKey: .backspace, modifierFlags: [], at: range, handled: &handled)

            guard handled == false else {
                return false
            }

            let substring = textView.attributedText.attributedSubstring(from: range)
            guard substring.length > 0,
                let attachment = substring.attribute(.attachment, at: 0, effectiveRange: nil) as? Attachment,
                attachment.selectBeforeDelete else {
                    return true
            }

            if attachment.isSelected {
                return true
            } else {
                attachment.isSelected = true
                return false
            }
        }

        if text == "\n" {
            richTextView.richTextViewDelegate?.richTextView(richTextView, didReceiveKey: .enter, modifierFlags: [], at: range, handled: &handled)

            guard handled == false else {
                return false
            }
        }

        if text == "\t" {
            richTextView.richTextViewDelegate?.richTextView(richTextView, didReceiveKey: .tab, modifierFlags: [], at: range, handled: &handled)

            guard handled == false else {
                return false
            }
        }

        applyFontFixForEmojiIfRequired(in: richTextView, at: range)
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        guard textView.delegate === self else { return }

        guard let richTextView = activeTextView else { return }
        applyFontFixForEmojiIfRequired(in: richTextView, at: textView.selectedRange)
        richTextView.richTextViewDelegate?.richTextView(richTextView, didChangeTextAtRange: richTextView.selectedRange)
    }

    // This func is required to handle a bug in NSTextStorage/UITextView where after inserting an emoji character, the
    // typing attributes are set to default Menlo font. This causes the editor to lose the applied font that exists before the emoji
    // character. The code looks for existing font information before emoji char and resets that in the typing attributes.
    private func applyFontFixForEmojiIfRequired(in textView: RichTextView, at range: NSRange) {
        guard let font = textView.typingAttributes[.font] as? UIFont,
            font.isAppleEmoji else {
                return
        }
        textView.typingAttributes[.font] = getDefaultFont(textView: textView, before: range)
    }

    private func getDefaultFont(textView: RichTextView, before range: NSRange) -> UIFont {
        var fontToApply: UIFont?
        let traversalRange = NSRange(location: 0, length: range.location)
        textView.enumerateAttribute(.font, in: traversalRange, options: [.longestEffectiveRangeNotRequired, .reverse]) { font, fontRange, stop in
            if let font = font as? UIFont,
                font.isAppleEmoji == false {
                fontToApply = font
                stop.pointee = true
            }
        }
        return fontToApply ?? textView.richTextStorage.defaultFont
    }
}
