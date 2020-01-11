//
//  RichTextView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

class RichTextView: AutogrowingTextView {
    let storage = TextStorage()

    weak var richTextViewDelegate: RichTextViewDelegate?

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding? {
        get { return storage.defaultTextFormattingProvider }
        set { storage.defaultTextFormattingProvider = newValue }
    }

    init(frame: CGRect = .zero, context: RichTextViewContext = RichTextViewContext.default) {
        let textContainer = TextContainer()
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: textContainer)
        layoutManager.delegate = self
        textContainer.textView = self
        self.delegate = context
    }

    var richTextStorage: TextStorage {
        return storage
    }

    weak var textProcessor: TextProcessor? {
        didSet {
            storage.delegate = textProcessor
        }
    }

    var textEndRange: NSRange {
        return storage.textEndRange
    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func invalidateLayout(for range: NSRange) {
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
    }

    func invalidateDisplay(for range: NSRange) {
        layoutManager.invalidateDisplay(forCharacterRange: range)
    }

    func insertAttachment(in range: NSRange, attachment: Attachment) {
        richTextStorage.insertAttachment(in: range, attachment: attachment)
    }

    func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        richTextStorage.replaceCharacters(in: range, with: attrString)
    }

    func replaceCharacters(in range: NSRange, with string: String) {
        // Delegate to function with attrString so that default attributes are automatically applied
        richTextStorage.replaceCharacters(in: range, with: NSAttributedString(string: string))
    }

    func attributeValue(at location: CGPoint, for attribute: NSAttributedString.Key) -> Any? {
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textStorage.length else {
            return nil
        }

        let attributes = textStorage.attributes(at: characterIndex, longestEffectiveRange: nil, in: textStorage.fullRange)
        return attributes[attribute]
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // TODO: revisit
        return false
    }

    func contents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.attributedText.enumerateContents(in: range)
    }
}

extension RichTextView: NSLayoutManagerDelegate  {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag,
            let textContainer = textContainer as? TextContainer,
            let textView = textContainer.textView else {
                return
        }

        textView.relayoutAttachments()
    }
}

extension RichTextView {
    func relayoutAttachments() {
        textStorage.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: textStorage.length), options: .longestEffectiveRangeNotRequired) { (attach, range, _) in
            guard let attachment = attach as? Attachment
                else { return }

            var frame = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
            frame.origin.y += self.textContainerInset.top

            var size = attachment.frame.size
            if size == .zero,
                let contentSize = attachment.contentView?.systemLayoutSizeFitting(bounds.size) {
                size = contentSize
            }

            frame = CGRect(origin: frame.origin, size: size)

            if attachment.isRendered == false {
                attachment.render(in: self)
                if let focusable = attachment.contentView as? Focusable {
                    focusable.setFocus()
                }
            }
            attachment.frame = frame
        }
    }
}
