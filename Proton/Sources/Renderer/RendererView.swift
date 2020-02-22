//
//  RendererView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

open class RendererView: UIView {
    private let readOnlyEditorView: EditorView

    public weak var delegate: RendererViewDelegate?

    public init(frame: CGRect = .zero, context: RendererViewContext = .shared) {
        readOnlyEditorView = EditorView(frame: frame, richTextViewContext: context.richTextRendererContext)
        super.init(frame: frame)
        setup()
    }

    init(editor: EditorView) {
        readOnlyEditorView = editor
        super.init(frame: editor.frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var font: UIFont? {
        get { return readOnlyEditorView.font }
        set { readOnlyEditorView.font = newValue }
    }

    public var attributedText: NSAttributedString {
        get { return readOnlyEditorView.attributedText }
        set { readOnlyEditorView.attributedText = newValue }
    }

    public var enableSelectionHandles: Bool {
        get { return readOnlyEditorView.enableSelectionHandles }
        set { readOnlyEditorView.enableSelectionHandles = false }
    }

    public var selectedRange: NSRange {
        get { return readOnlyEditorView.selectedRange }
        set { readOnlyEditorView.selectedRange = newValue }
    }

    public var selectedText: NSAttributedString {
        get { return readOnlyEditorView.selectedText }
    }

    public var contents: [EditorContent] {
        get { return readOnlyEditorView.contents() }
    }

    public var contentOffset: CGPoint {
        get { return readOnlyEditorView.contentOffset }
        set { readOnlyEditorView.contentOffset = newValue }
    }

    public func scrollRangeToVisible(_ range: NSRange) {
        readOnlyEditorView.scrollRangeToVisible(range)
    }

    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        readOnlyEditorView.scrollRectToVisible(rect, animated: animated)
    }

    public func contents(in range: NSRange? = nil) -> [EditorContent] {
        return readOnlyEditorView.contents(in: range)
    }

    func didTap(at location: CGPoint) {
        readOnlyEditorView.richTextView.didTap(at: location)
    }

    public func rects(for range: NSRange) -> [CGRect] {
        return readOnlyEditorView.rects(for: range)
    }

    private func setup() {
        readOnlyEditorView.isEditable = false

        readOnlyEditorView.translatesAutoresizingMaskIntoConstraints = false
        readOnlyEditorView.richTextView.richTextViewDelegate = self

        addSubview(readOnlyEditorView)
        NSLayoutConstraint.activate([
            readOnlyEditorView.topAnchor.constraint(equalTo: topAnchor),
            readOnlyEditorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            readOnlyEditorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            readOnlyEditorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
    }
}

extension RendererView: RichTextViewDelegate {
    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        delegate?.didChangeSelection(self, range: range)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) { }

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) { }

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) { }

    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange) { }

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        readOnlyEditorView.relayoutAttachments()
    }

    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        delegate?.didTap(self, didTapAtLocation: location, characterRange: characterRange)
    }
}

extension RendererView {
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
        readOnlyEditorView.addAttributes(attributes, at: range)
    }

    public func removeAttributes(_ attributes: [NSAttributedString.Key], at range: NSRange) {
        readOnlyEditorView.removeAttributes(attributes, at: range)
    }

    public func addAttribute(_ name: NSAttributedString.Key, value: Any, at range: NSRange) {
        readOnlyEditorView.addAttribute(name, value: value, at: range)
    }

    public func removeAttribute(_ name: NSAttributedString.Key, at range: NSRange) {
        readOnlyEditorView.removeAttribute(name, at: range)
    }
}
