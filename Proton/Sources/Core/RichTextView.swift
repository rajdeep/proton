//
//  RichTextView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

protocol RichTextViewDelegate: class {
    func didChangeSelection(_ textView: RichTextView, range: NSRange, attributes: [EditorAttribute], contentType: EditorContent.Name)
}

class RichTextView: AutogrowingTextView {
    let storage = TextStorage()

    weak var richTextViewDelegate: RichTextViewDelegate?

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding? {
        get { return storage.defaultTextFormattingProvider }
        set { storage.defaultTextFormattingProvider = newValue }
    }

    init(frame: CGRect) {
        let textContainer = TextContainer()
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: textContainer)
        layoutManager.delegate = self
        textContainer.textView = self
    }

    var richTextStorage: TextStorage {
        return storage
    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func invalidateLayout(for range: NSRange) {
        layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
    }

    func invalidateDisaplay(for range: NSRange) {
        layoutManager.invalidateDisplay(forCharacterRange: range)
    }

    func attributeValue(at location: CGPoint, for attribute: NSAttributedString.Key) -> Any? {
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textStorage.length else {
            return nil
        }

        let attributes = textStorage.attributes(at: characterIndex, longestEffectiveRange: nil, in: textStorage.fullRange)
        return attributes[attribute]
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
    func relayoutAttachments() { }
}
