//
//  EditorView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 5/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

open class EditorView: UIView {
    let editor: RichTextView

    public override init(frame: CGRect) {
        editor = RichTextView(frame: frame)
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var contentInset: UIEdgeInsets {
        get { editor.contentInset }
        set { editor.contentInset = newValue }
    }

    public var textContainerInset: UIEdgeInsets {
        get { editor.textContainerInset }
        set { editor.textContainerInset = newValue }
    }

    public var contentLength: Int {
        return attributedText.length
    }

    public override var backgroundColor: UIColor? {
        didSet {
            editor.backgroundColor = backgroundColor
        }
    }

    public var font: UIFont? = UIFont.systemFont(ofSize: 17) {
        didSet { editor.typingAttributes[.font] = font }
    }

    public var paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle() {
        didSet { editor.typingAttributes[.paragraphStyle] = paragraphStyle }
    }

    public var maxHeight: CGFloat {
        get { editor.maxHeight }
        set { editor.maxHeight = newValue }
    }

    public var attributedText: NSAttributedString {
        get { return editor.attributedText }
        set { editor.attributedText = newValue }
    }

    public var selectedRange: NSRange {
        get { return editor.selectedRange }
        set { editor.selectedRange = newValue }
    }

    public var typingAttributes: [NSAttributedString.Key: Any] {
        get { return editor.typingAttributes }
        set { editor.typingAttributes = newValue }
    }

    func setup() {
        editor.autocorrectionType = .no

        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.defaultTextFormattingProvider = self

        addSubview(editor)
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: topAnchor),
            editor.bottomAnchor.constraint(equalTo: bottomAnchor),
            editor.leadingAnchor.constraint(equalTo: leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

        setupTextStyles()
        typingAttributes = [
            NSAttributedString.Key.font: font ?? UIFont.systemFont(ofSize: 17),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
    }

    private func setupTextStyles() {
        paragraphStyle.lineSpacing = 6
        paragraphStyle.firstLineHeadIndent = 8
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return editor.becomeFirstResponder()
    }

    public func insertAttachment(in range: NSRange, attachment: Attachment) {
        // TODO: handle undo

        editor.insertAttachment(in: range, attachment: attachment)
    }

    public func resignFocus() {
        editor.resignFirstResponder()
    }

    public func scrollRangeToVisible(range: NSRange) {
        editor.scrollRangeToVisible(range)
    }

    public func scrollRectToVisible(rect: CGRect, animated: Bool) {
        editor.scrollRectToVisible(rect, animated: animated)
    }

    public func replaceCharacters(in range: NSRange, with attriburedString: NSAttributedString) {
        editor.textStorage.replaceCharacters(in: range, with: attriburedString)
    }
}

extension EditorView {
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
        self.editor.storage.addAttributes(attributes, range: range)
        // TODO: propagate to attachments
    }

    public func removeAttributes(_ attributes: [NSAttributedString.Key], at range: NSRange) {
        self.editor.storage.removeAttributes(attributes, range: range)
       // TODO: propagate to attachments
    }

    public func addAttribute(_ name: NSAttributedString.Key, value: Any, at range: NSRange) {
        self.addAttributes([name: value], at: range)
    }

    public func removeAttribute(_ name: NSAttributedString.Key, at range: NSRange) {
        self.removeAttributes([name], at: range)
    }
}

extension EditorView: DefaultTextFormattingProviding { }
