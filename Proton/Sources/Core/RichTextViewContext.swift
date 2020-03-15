//
//  RichTextViewContext.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

class RichTextViewContext: NSObject, UITextViewDelegate {
    var activeTextView: RichTextView?

    func textView(
        _ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange, interaction: UITextItemInteraction
    ) -> Bool {
        return interaction != .presentActions
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        activeTextView = textView as? RichTextView

        guard let richTextView = activeTextView else { return }
        let range = textView.selectedRange

        resetAttachmentSelection(textView)
        guard range.length > 0 else {
            var attributes = richTextView.typingAttributes
            let contentType = attributes[.contentType] as? EditorContent.Name ?? .unknown
            attributes[.contentType] = nil
            richTextView.richTextViewDelegate?.richTextView(
                richTextView, didChangeSelection: range, attributes: attributes,
                contentType: contentType)
            return
        }

        let substring = textView.attributedText.attributedSubstring(from: range)

        // Mark attachments as selected if there are any in the selected range
        substring.enumerateAttribute(
            .attachment, in: substring.fullRange, options: .longestEffectiveRangeNotRequired
        ) { attachment, range, _ in
            if let attachment = attachment as? Attachment {
                attachment.isSelected = true
            }
        }

        var attributes = substring.attributes(at: 0, effectiveRange: nil)
        let contentType = attributes[.contentType] as? EditorContent.Name ?? .unknown
        attributes[.contentType] = nil
        richTextView.richTextViewDelegate?.richTextView(
            richTextView, didChangeSelection: range, attributes: attributes,
            contentType: contentType)
    }

    func resetAttachmentSelection(_ textView: UITextView) {
        guard let attributedText = textView.attributedText else { return }
        attributedText.enumerateAttribute(
            .attachment, in: attributedText.fullRange, options: .longestEffectiveRangeNotRequired
        ) { attachment, _, _ in
            if let attachment = attachment as? Attachment {
                attachment.isSelected = false
            }
        }
    }
}
