//
//  RichTextViewContext.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 7/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

class RichTextViewContext: NSObject, UITextViewDelegate {

    static let `default` = RichTextViewContext()

    var activeTextView: RichTextView?

    func textViewDidBeginEditing(_ textView: UITextView) {
        activeTextView = textView as? RichTextView
        guard let richTextView = activeTextView else { return }
        activeTextView?.richTextViewDelegate?.richTextView(richTextView, didReceiveFocusAt: textView.selectedRange)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        defer {
            activeTextView = nil
        }
        guard let richTextView = activeTextView else { return }
        activeTextView?.richTextViewDelegate?.richTextView(richTextView, didLoseFocusFrom: textView.selectedRange)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let richTextView = activeTextView else { return true }
        // if backspace
        var handled = false
        if (text.isEmpty && range.length > 0) || (text.isEmpty && range == .zero) {
            richTextView.richTextViewDelegate?.richTextView(richTextView, didReceiveKey: .backspace, at: range, handled: &handled)

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
            richTextView.richTextViewDelegate?.richTextView(richTextView, didReceiveKey: .enter, at: range, handled: &handled)

            guard handled == false else {
                return false
            }
        }

        return true
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return interaction != .presentActions
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        activeTextView = textView as? RichTextView

        guard let richTextView = activeTextView else { return }

        let range = textView.selectedRange
        let substring = textView.attributedText.attributedSubstring(from: range)
        guard substring.length > 0 else {
            resetAttachmentSelection(textView)

            if textView.text.isEmpty == false,
                textView.selectedRange.location - 1 > textView.attributedText.length {
                // TODO: Add attributes and contentTyoe
                richTextView.richTextViewDelegate?.richTextView(richTextView, didChangeSelection: range, attributes: [], contentType: .unknown)
            }
            return
        }

        substring.enumerateAttribute(.attachment, in: substring.fullRange, options: .longestEffectiveRangeNotRequired) { attachment, _, _ in
            if let attachment = attachment as? Attachment {
                attachment.isSelected = true
            }
        }

        // TODO: Add attributes and contentTyoe
        richTextView.richTextViewDelegate?.richTextView(richTextView, didChangeSelection: range, attributes: [], contentType: .unknown)
    }

    func resetAttachmentSelection(_ textView: UITextView) {
        guard let attributedText = textView.attributedText else { return }
        attributedText.enumerateAttribute(.attachment, in: attributedText.fullRange, options: .longestEffectiveRangeNotRequired) { attachment, _, _ in
            if let attachment = attachment as? Attachment {
                attachment.isSelected = false
            }
        }
    }
}
