//
//  EditorView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 5/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public protocol BoundsObserving: class {
    func didChangeBounds(_ bounds: CGRect)
}

open class EditorView: UIView {
    let richTextView: RichTextView

    let context: RichTextViewContext
    public weak var delegate: EditorViewDelegate?
    var textProcessor: TextProcessor?

    // Making this a convenience init fails the test `testRendersWidthRangeAttachment` as the init of a class subclassed from
    // `EditorView` is retured as type `EditorView` and not the class itself, causing the test to fail.
    public init(frame: CGRect = .zero, context: EditorViewContext = .shared) {
        self.context = context.richTextViewContext
        self.richTextView = RichTextView(frame: frame, context: self.context)

        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    init(frame: CGRect, richTextViewContext: RichTextViewContext) {
        self.context = richTextViewContext
        self.richTextView = RichTextView(frame: frame, context: context)

        super.init(frame: frame)

        self.textProcessor = TextProcessor(editor: self)
        self.richTextView.textProcessor = textProcessor
        setup()
    }

    open var editorInputAccessoryView: UIView? {
        get { return richTextView.inputAccessoryView }
        set { richTextView.inputAccessoryView = newValue }
    }

    open var editorInputView: UIView? {
        get { return richTextView.inputView }
        set { richTextView.inputView = newValue }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var placeholderText: NSAttributedString? {
        get { richTextView.placeholderText }
        set { richTextView.placeholderText = newValue}
    }

    public var contentInset: UIEdgeInsets {
        get { richTextView.contentInset }
        set { richTextView.contentInset = newValue }
    }

    public var textContainerInset: UIEdgeInsets {
        get { richTextView.textContainerInset }
        set { richTextView.textContainerInset = newValue }
    }

    public var contentLength: Int {
        return attributedText.length
    }

    public var isEditable: Bool {
        get { richTextView.isEditable }
        set { richTextView.isEditable = newValue }
    }

    public var isEmpty: Bool {
        return richTextView.attributedText.length == 0
    }

    public var selectedText: NSAttributedString {
        return attributedText.attributedSubstring(from: selectedRange)
    }

    public override var backgroundColor: UIColor? {
        didSet {
            richTextView.backgroundColor = backgroundColor
        }
    }

    public var font: UIFont? = UIFont.systemFont(ofSize: 17) {
        didSet { richTextView.typingAttributes[.font] = font }
    }

    public var paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle() {
        didSet { richTextView.typingAttributes[.paragraphStyle] = paragraphStyle }
    }

    public var maxHeight: CGFloat {
        get { richTextView.maxHeight }
        set { richTextView.maxHeight = newValue }
    }

    public var attributedText: NSAttributedString {
        get { return richTextView.attributedText }
        set { richTextView.attributedText = newValue }
    }

    public var selectedRange: NSRange {
        get { return richTextView.selectedRange }
        set { richTextView.selectedRange = newValue }
    }

    public var typingAttributes: [NSAttributedString.Key: Any] {
        get { return richTextView.typingAttributes }
        set { richTextView.typingAttributes = newValue }
    }

    public var boundsObserver: BoundsObserving? {
        get { richTextView.boundsObserver }
        set { richTextView.boundsObserver = newValue }
    }

    public var textEndRange: NSRange {
        return richTextView.textEndRange
    }

    func setup() {
        richTextView.autocorrectionType = .no

        richTextView.translatesAutoresizingMaskIntoConstraints = false
        richTextView.defaultTextFormattingProvider = self
        richTextView.richTextViewDelegate = self

        addSubview(richTextView)
        NSLayoutConstraint.activate([
            richTextView.topAnchor.constraint(equalTo: topAnchor),
            richTextView.bottomAnchor.constraint(equalTo: bottomAnchor),
            richTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            richTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])

        typingAttributes = [
            NSAttributedString.Key.font: font ?? UIFont.systemFont(ofSize: 17),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return richTextView.becomeFirstResponder()
    }

    public func insertAttachment(in range: NSRange, attachment: Attachment) {
        // TODO: handle undo
        richTextView.insertAttachment(in: range, attachment: attachment)
    }

    public func setFocus() {
        richTextView.becomeFirstResponder()
    }

    public func resignFocus() {
        richTextView.resignFirstResponder()
    }

    public func scrollRangeToVisible(_ range: NSRange) {
        richTextView.scrollRangeToVisible(range)
    }

    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        richTextView.scrollRectToVisible(rect, animated: animated)
    }

    public func contents(in range: NSRange? = nil) -> [EditorContent] {
        let contents =  richTextView.contents(in: range)
        return Array(contents)
    }

    /// Transforms `EditorContent` into given type. This function can also be used to encode content into a different type for  e.g. encoding the contents to JSON. Encoding
    /// is  a type of transformation that can also be decoded.
    /// - Parameter range: Range of `Editor` to transform the contents. By default, entire range is used.
    /// - Parameter transformer: Transformer capable ot transforming `EditorContent` to given type
    public func transformContents<T: EditorContentTransforming>(in range: NSRange? = nil, using transformer: T) -> [T.TransformedType] {
        return richTextView.transformContents(in: range, using: transformer)
    }

    public func replaceCharacters(in range: NSRange, with attriburedString: NSAttributedString) {
        richTextView.replaceCharacters(in: range, with: attriburedString)
    }

    /// Replaces the characters in the given range with the string provided.
    /// - Attention:
    /// The string provided will use the default `font` and `paragraphStyle` set in the `EditorView`. It will not retain any other attributes already applied on
    /// the range of text being replaced by the `string`. If you would like add any other attributes, it is best to use `replaceCharacters` with the paramater value of
    /// type `NSAttributedString` that may have additional attributes defined, as well as customised `font` and `paragraphStyle` applied.
    /// - Parameter range: Range of text to replace. For an empty `EditorView`, you may pass `NSRange.zero` to insert text at the beginning.
    /// - Parameter string: String to replace the range of text with. The string will use default `font` and `paragraphStyle` defined in the `EditorView`.
    public func replaceCharacters(in range: NSRange, with string: String) {
        var attributes: RichTextAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
        if let font = self.font {
           attributes[NSAttributedString.Key.font] = font
        }
        let attributedString = NSAttributedString(string: string, attributes: attributes)
        richTextView.replaceCharacters(in: range, with: attributedString)
    }

    public func registerProcessor(_ processor: TextProcessing) {
        textProcessor?.register(processor)
    }

    public func unregisterProcessor(_ processor: TextProcessing) {
        textProcessor?.unregister(processor)
    }
}

extension EditorView {
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
        self.richTextView.addAttributes(attributes, range: range)
        self.richTextView.enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) { value, rangeInContainer, _ in
            if let attachment = value as? Attachment {
                attachment.addedAttributesOnContainingRange(rangeInContainer: rangeInContainer, attributes: attributes)
            }
        }
    }

    public func removeAttributes(_ attributes: [NSAttributedString.Key], at range: NSRange) {
        self.richTextView.removeAttributes(attributes, range: range)
        self.richTextView.enumerateAttribute(.attachment, in: range, options: .longestEffectiveRangeNotRequired) { value, rangeInContainer, _ in
            if let attachment = value as? Attachment {
                attachment.removedAttributesFromContainingRange(rangeInContainer: rangeInContainer, attributes: attributes)
            }
        }
    }

    public func addAttribute(_ name: NSAttributedString.Key, value: Any, at range: NSRange) {
        self.addAttributes([name: value], at: range)
    }

    public func removeAttribute(_ name: NSAttributedString.Key, at range: NSRange) {
        self.removeAttributes([name], at: range)
    }
}

extension EditorView: DefaultTextFormattingProviding { }

extension EditorView: RichTextViewDelegate {
    func richTextView(_ richTextView: RichTextView, didChangeSelection range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        delegate?.editor(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveKey key: EditorKey, at range: NSRange, handled: inout Bool) {
        delegate?.editor(self, didReceiveKey: key, at: range, handled: &handled)
    }

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) {
        delegate?.editor(self, didReceiveFocusAt: range)
    }

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) {
        delegate?.editor(self, didLoseFocusFrom: range)
    }

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        guard finished else { return }
        relayoutAttachments()
    }

    func richTextView(_ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?) { }
}

extension EditorView {
    func invalidateLayout(for range: NSRange) {
        richTextView.invalidateLayout(for: range)
    }

    func relayoutAttachments() {
        richTextView.enumerateAttribute(NSAttributedString.Key.attachment, in: NSRange(location: 0, length: richTextView.contentLength), options: .longestEffectiveRangeNotRequired) { (attach, range, _) in
            guard let attachment = attach as? Attachment
                else { return }

            var frame = richTextView.boundingRect(forGlyphRange: range)
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

public extension EditorView {
    func convertToRenderer() -> RendererView {
        return RendererView(editor: self)
    }
}
