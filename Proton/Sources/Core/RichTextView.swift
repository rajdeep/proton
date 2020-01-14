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
    private let storage = TextStorage()

    weak var richTextViewDelegate: RichTextViewDelegate?

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding? {
        get { return storage.defaultTextFormattingProvider }
        set { storage.defaultTextFormattingProvider = newValue }
    }

    private let placeholderLabel = UILabel()

    var placeholderText: NSAttributedString? {
        didSet {
            placeholderLabel.attributedText = placeholderText
        }
    }

    init(frame: CGRect = .zero, context: RichTextViewContext) {
        let textContainer = TextContainer()
        let layoutManager = NSLayoutManager()

        layoutManager.addTextContainer(textContainer)
        storage.addLayoutManager(layoutManager)

        super.init(frame: frame, textContainer: textContainer)
        layoutManager.delegate = self
        textContainer.textView = self
        self.delegate = context

        setupPlaceholder()
    }

    var richTextStorage: TextStorage {
        return storage
    }

    var contentLength: Int {
        return storage.length
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

    private func setupPlaceholder() {
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.numberOfLines = 0
        placeholderLabel.lineBreakMode = .byWordWrapping

        addSubview(placeholderLabel)
        placeholderLabel.attributedText = placeholderText
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textContainerInset.top),
            placeholderLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -textContainerInset.bottom),
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textContainer.lineFragmentPadding),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -textContainer.lineFragmentPadding),
        ])

        NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: self, queue: nil) { [weak self] _ in
            self?.updatePlaceholderVisibility()
        }
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

    func transformContents<T: EditorContentTransforming>(in range: NSRange? = nil, using transformer: T) -> [T.TransformedType] {
        return contents(in: range).compactMap(transformer.transform)
    }

    func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        richTextStorage.replaceCharacters(in: range, with: attrString)
        updatePlaceholderVisibility()
    }

    func replaceCharacters(in range: NSRange, with string: String) {
        // Delegate to function with attrString so that default attributes are automatically applied
        richTextStorage.replaceCharacters(in: range, with: NSAttributedString(string: string))
    }

    private func updatePlaceholderVisibility() {
        self.placeholderLabel.attributedText = self.attributedText.length == 0 ? self.placeholderText : NSAttributedString()
    }

    func attributeValue(at location: CGPoint, for attribute: NSAttributedString.Key) -> Any? {
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textStorage.length else {
            return nil
        }

        let attributes = textStorage.attributes(at: characterIndex, longestEffectiveRange: nil, in: textStorage.fullRange)
        return attributes[attribute]
    }

    func boundingRect(forGlyphRange range: NSRange) -> CGRect {
        return layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // TODO: revisit
        return false
    }

    func contents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.attributedText.enumerateContents(in: range)
    }

    func addAttributes(_ attrs: [NSAttributedString.Key : Any], range: NSRange) {
        storage.addAttributes(attrs, range: range)
    }

    func removeAttributes(_ attrs: [NSAttributedString.Key], range: NSRange) {
        storage.removeAttributes(attrs, range: range)
    }

    func enumerateAttribute(_ attrName: NSAttributedString.Key, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [], using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        storage.enumerateAttribute(attrName, in: enumerationRange, options: opts, using: block)
    }

    func rangeOfCharacter(at point: CGPoint) -> NSRange? {
        return characterRange(at: point)?.toNSRange(in: self)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            didTap(at: position)
        }
    }

    func didTap(at location: CGPoint) {
        let characterRange = rangeOfCharacter(at: location)
        richTextViewDelegate?.richTextView(self, didTapAtLocation: location, characterRange: characterRange)
    }
}

extension RichTextView: NSLayoutManagerDelegate  {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        richTextViewDelegate?.richTextView(self, didFinishLayout: layoutFinishedFlag)
    }
}
