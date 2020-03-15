//
//  RendererView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

/// A scrollable, multiline text region capable of resizing itself based of the height of the content. Maximum height of `RendererView`
/// may be restricted using an absolute value or by using auto-layout constraints. Instantiation of `RendererView` is simple and straightforward
/// and can be used to host simple formatted text or complex layout containing multiple nested `RendererView` via use of `Attachment`.
open class RendererView: UIView {
    private let readOnlyEditorView: EditorView

    /// An object interested in intercepting and responding to user interaction like tap and selecting changes in the `RendererView`.
    public weak var delegate: RendererViewDelegate?

    /// Initializes the RendererView
    /// - Parameters:
    ///   - frame: Initial frame to be used for `RendererView`
    ///   - context: Optional context to be used. `RendererViewContext` is link between `RendererCommandExecutor` and the `RendererView`.
    ///   `RendererCommandExecutor` needs to have same context as the `RendererView` to execute a command on it. Unless you need to have
    ///    restriction around some commands to be restricted in execution on certain specific renderers, the default value may be used.
    public init(frame: CGRect = .zero, context: RendererViewContext = .shared) {
        readOnlyEditorView = EditorView(
            frame: frame, richTextViewContext: context.richTextRendererContext)
        super.init(frame: frame)
        setup()
    }

    init(editor: EditorView) {
        readOnlyEditorView = editor
        super.init(frame: editor.frame)
        setup()
    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Default font to be used for the rendered content.
    /// - Note:
    /// This font is only applied in case where the `attributedText` does not have
    /// font information in the content. If the `attributedText` already has an attribute applied
    /// for font, this font will be ignored.
    public var font: UIFont {
        get { readOnlyEditorView.font }
        set { readOnlyEditorView.font = newValue }
    }

    /// Content rendered in the `RendererView`.
    public var attributedText: NSAttributedString {
        get { readOnlyEditorView.attributedText }
        set { readOnlyEditorView.attributedText = newValue }
    }

    /// Determines if the selection handles should be shown when selecting a range
    /// programatically by using `selectedRange` property. Defaults to `true`
    public var enableSelectionHandles: Bool {
        get { readOnlyEditorView.enableSelectionHandles }
        set { readOnlyEditorView.enableSelectionHandles = false }
    }

    /// Gets or sets the selected range.
    public var selectedRange: NSRange {
        get { readOnlyEditorView.selectedRange }
        set { readOnlyEditorView.selectedRange = newValue }
    }

    /// The types of data converted to tappable URLs in the renderer view.
    public var dataDetectorTypes: UIDataDetectorTypes {
        get { readOnlyEditorView.dataDetectorTypes }
        set { readOnlyEditorView.dataDetectorTypes = newValue }
    }

    /// Selected text in the editor.
    public var selectedText: NSAttributedString {
        return readOnlyEditorView.selectedText
    }

    /// Returns the visible text range.
    /// - Note:
    /// The range may also contains lines that are partially visible owing to the current scroll position.
    public var visibleRange: NSRange {
        return readOnlyEditorView.visibleRange
    }

    /// Get all the content from `Renderer`.
    /// - SeeAlso:
    /// If you need to get content in a given range, please use `contents(in range:NSRange)`.
    public var contents: [EditorContent] {
        return readOnlyEditorView.contents()
    }

    /// Gets and sets the content offset.
    public var contentOffset: CGPoint {
        get { readOnlyEditorView.contentOffset }
        set { readOnlyEditorView.contentOffset = newValue }
    }

    /// Scrolls the given range to visible area of the `RendererView`. The scroll only changes enough to
    /// make the range visible i.e. the it does not scroll far enough such that given range is centred
    /// in the visible area of `Renderer`.
    /// No-op if the range is already visible.
    /// - Parameter range: Range to scroll to.
    public func scrollRangeToVisible(_ range: NSRange) {
        readOnlyEditorView.scrollRangeToVisible(range)
    }

    /// Scrolls the given rectangle to visible area of `RendererView`
    /// - Parameters:
    ///   - rect: Rectangle to scroll to.
    ///   - animated: Determines if the scroll action should animate
    public func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        readOnlyEditorView.scrollRectToVisible(rect, animated: animated)
    }

    /// Gets the contents in the given range
    /// - Parameter range: Range to get contents from.
    public func contents(in range: NSRange? = nil) -> [EditorContent] {
        return readOnlyEditorView.contents(in: range)
    }

    /// Gets the bounding rectangles for the given range. If the range spans across multiple lines,
    /// in the `RendererView`, a rectangle is returned for each of the line.
    /// - Parameter range: Range to get bounding rectangles for.
    public func rects(for range: NSRange) -> [CGRect] {
        return readOnlyEditorView.rects(for: range)
    }

    func didTap(at location: CGPoint) {
        readOnlyEditorView.richTextView.didTap(at: location)
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
    func richTextView(
        _ richTextView: RichTextView, didChangeSelection range: NSRange,
        attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name
    ) {
        delegate?.didChangeSelection(self, range: range)
    }

    func richTextView(
        _ richTextView: RichTextView, didReceiveKey key: EditorKey, at range: NSRange,
        handled: inout Bool
    ) {}

    func richTextView(_ richTextView: RichTextView, didReceiveFocusAt range: NSRange) {}

    func richTextView(_ richTextView: RichTextView, didLoseFocusFrom range: NSRange) {}

    func richTextView(_ richTextView: RichTextView, didChangeTextAtRange range: NSRange) {}

    func richTextView(_ richTextView: RichTextView, didFinishLayout finished: Bool) {
        readOnlyEditorView.relayoutAttachments()
    }

    func richTextView(
        _ richTextView: RichTextView, didTapAtLocation location: CGPoint, characterRange: NSRange?
    ) {
        delegate?.didTap(self, didTapAtLocation: location, characterRange: characterRange)
    }
}

extension RendererView {

    /// Adds given attributes to the range provided. If the range already contains a value for an attribute being provided,
    /// existing value will be overwritten by the new value provided in the attributes.
    /// - Parameters:
    ///   - attributes: Attributes to be added.
    ///   - range: Range on which attributes should be applied to.
    public func addAttributes(_ attributes: [NSAttributedString.Key: Any], at range: NSRange) {
        readOnlyEditorView.addAttributes(attributes, at: range)
    }

    /// Removes the given attributes from the range provided. If the attribute does not exist in the range, it will be a no-op.
    /// - Parameters:
    ///   - attributes: Attributes to remove.
    ///   - range: Range to remove the attributes from.
    public func removeAttributes(_ attributes: [NSAttributedString.Key], at range: NSRange) {
        readOnlyEditorView.removeAttributes(attributes, at: range)
    }

    /// Adds given attribute to the range provided. If the attribute already exists in the range, it will be overwritten with the new value provided here.
    /// - Parameters:
    ///   - name: Key of the attribute to add.
    ///   - value: Value of the attribute.
    ///   - range: Range to which attribute should be added.
    public func addAttribute(_ name: NSAttributedString.Key, value: Any, at range: NSRange) {
        readOnlyEditorView.addAttribute(name, value: value, at: range)
    }

    /// Removes the attribute from given range. If the attribute does not exist in the range, it is a no-op.
    /// - Parameters:
    ///   - name: Key of attribute to be removed.
    ///   - range: Range from which attribute should be removed.
    public func removeAttribute(_ name: NSAttributedString.Key, at range: NSRange) {
        readOnlyEditorView.removeAttribute(name, at: range)
    }
}
