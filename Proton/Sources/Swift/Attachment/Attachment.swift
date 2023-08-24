//
//  EditorAttachment.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
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
import ProtonCore

/// Describes an object (typically attachment view) that may change size during the layout pass
public protocol DynamicBoundsProviding: AnyObject {
    func sizeFor(attachment: Attachment, containerSize: CGSize, lineRect: CGRect) -> CGSize
}

/// Describes an object capable of providing offsets for the `Attachment`. The value is used to offset the `Attachment` when rendered alongside the text. This may
/// be used to align the content baselines in `Attachment` content to that of it's container's content baselines.
/// - Note:
/// This function may be called m0re than once in the same rendering pass. Changing offsets does not resize the container i.e. unlike how container resizes to fit the attachment, if the
/// offset is change such that the attachment ends up rendering outside the bounds of it's container, it will not resize the container.
/// - Attention:
/// While offset can be provided for any type of `Attachment` i.e. Inline or Block, it is recommended that offset be provided only for Inline. If an offset is provided for Block attachment,
/// it is possible that the attachment starts overlapping the content in `Editor` in the following line since the offset does not affect the line height.
public protocol AttachmentOffsetProviding: AnyObject {
    func offset(for attachment: Attachment, in textContainer: NSTextContainer, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGPoint
}

/// An attachment can be used as a container for any view object. Based on the `AttachmentSize` provided, the attachment automatically renders itself alongside the text in `EditorView`.
/// `Attachment` also provides helper functions like `deleteFromContainer` and `rangeInContainer`
open class Attachment: NSTextAttachment, BoundsObserving {

    private var view: AttachmentContentView? = nil
    private var content: AttachmentContent = .image(UIImage())
    private var size: AttachmentSize? = nil
    private var isBlockAttachment: Bool = false
    private let selectionView = SelectionView()
    private(set) var cachedContainerSize: CGSize?
    private var indexInContainer: Int?
    private let backgroundColor: UIColor?

    var cachedBounds: CGRect?

    /// Governs if the attachment should be selected before being deleted. When `true`, tapping the backspace key the first time on range containing `Attachment` will only
    /// select the attachment i.e. show as highlighted. Tapping the backspace again will delete the attachment. If the value is `false`, the attachment will be deleted on the first backspace itself.
    public var selectBeforeDelete = false

    /// Attributed string representation of the `Attachment`. This can be used directly to replace a range of text in `EditorView`
    /// ### Usage Example ###
    /// ```
    /// let attachment = Attachment(PanelView(), size: .fullWidth)
    /// let attrString = NSMutableAttributedString(string: "This is a test string")
    /// attrString.append(attachment.string)
    /// editor.attributedText = attrString
    /// ```
    public var string: NSAttributedString {
       return stringWithAttributes(attributes: attributes)
    }

    /// Name of the content contained within the `Attachment`
    public var name: EditorContent.Name? {
        return view?.name
    }

    public var contentEditors: [EditorView] {
        guard let contentView else { return [] }
        return contentView.subviews.compactMap{ $0 as? EditorView }
    }

    var isImageBasedAttachment: Bool {
        self.view == nil
    }

    var isRendered: Bool {
        return view?.superview != nil
    }

    var isSelected: Bool = false {
        didSet {
            guard let view = self.view else { return }
            if isSelected {
                selectionView.addTo(parent: view)
            } else {
                selectionView.removeFromSuperview()
            }
        }
    }

    @objc
    var spacer: NSAttributedString {
        let spacer = isBlockAttachment == true ? NSAttributedString(string: "\n", attributes: [.blockContentType: EditorContentName.newline()]) : NSAttributedString(string: " ")
        return spacer
    }
    
    @objc
    var spacerCharacterSet: CharacterSet {
        return isBlockAttachment == true ? .newlines : .whitespaces
    }

    var attributes: [NSAttributedString.Key: Any] {
        let value = name ?? EditorContent.Name.unknown
        let isBlockAttachment = self.isBlockAttachment == true
        let contentKey: NSAttributedString.Key = isBlockAttachment ? .blockContentType : .inlineContentType
        return [
            contentKey: value,
            .isBlockAttachment: isBlockAttachment,
            .isInlineAttachment: !isBlockAttachment
        ]
    }

    var isContainerDependentSizing: Bool {
        guard contentView as? DynamicBoundsProviding == nil else {
            return false
        }

        switch size {
        case .fullWidth, .percent, .matchContent:
            return true
        default:
            return false
        }
    }

    final var frame: CGRect? {
        get { view?.frame }
        set {
            guard let newValue = newValue,
                view?.frame.equalTo(newValue) == false else { return }

            view?.frame = newValue
        }
    }

    /// `EditorView` containing this attachment
    public private(set) weak var containerEditorView: EditorView?

    /// Offsets for the attachment. Can be used to align attachment with the text. Defaults to `.zero`
    public weak var offsetProvider: AttachmentOffsetProviding?

    /// Name of the content for the `EditorView`
    /// - SeeAlso:
    /// `EditorView`
    public var containerContentName: EditorContent.Name? {
        return containerEditorView?.contentName
    }

    private var containerTextView: RichTextView? {
        return containerEditorView?.richTextView
    }

    public private(set) var contentView: UIView? {
        get { view?.subviews.first }
        set {
            view?.subviews.forEach { $0.removeFromSuperview() }
            if let contentView = newValue {
                view?.addSubview(contentView)
            }
        }
    }

    /// Bounds of the container
    public var containerBounds: CGRect? {
        return containerTextView?.bounds
    }

    /// The bounds rectangle, which describes the attachment's location and size in its own coordinate system.
    public override var bounds: CGRect {
        didSet { view?.bounds = bounds }
    }

    /// Initializes an attachment with the image provided.
    /// - Note: Image and Size can be updated by invoking `updateImage(image: size:)` at any time
    /// - Parameter image: Image to be used to display in the attachment.  Image is rendered as Inline content.
    public init(image: AttachmentImage) {
        backgroundColor = nil
        super.init(data: nil, ofType: nil)
        setup(image: image)
    }

    /// Initializes the attachment with the given content view
    /// - Parameters:
    ///   - contentView: Content view to be hosted within the attachment
    ///   - size: Size rule for attachment
    ///   - backgroundColor: Background color of attachment. Can be used with DEBUG to track the attachment size/location with respect to content view
    public init(_ contentView: AttachmentView, size: AttachmentSize, backgroundColor: UIColor? = nil) {
        self.backgroundColor = backgroundColor
        super.init(data: nil, ofType: nil)
        setup(contentView: contentView, size: size)
    }

    private func setup(contentView: AttachmentView, size: AttachmentSize) {
        let view = AttachmentContentView(name: contentView.name, frame: contentView.frame)
        self.view = view
        self.size = size
        self.image = nil
        self.isBlockAttachment = contentView.type == .block
        self.content = .view(view, size: size)
        self.view?.attachment = self
        initialize(contentView: contentView)
    }

    private func setup(image: AttachmentImage) {
        self.content = .image(image.image)
        self.isBlockAttachment = image.type == .block
        self.view = nil
        self.size = nil
        self.image = image.image
        self.bounds = CGRect(origin: .zero, size: image.size)
    }

    private func initialize(contentView: AttachmentView) {
        self.contentView = contentView
        setup()
        self.bounds = contentView.bounds

        // Required to disable rendering of default attachment image on iOS 13+
        self.image = (backgroundColor ?? UIColor.clear).image()
    }

    private func setup() {
        guard let contentView = contentView else {
            assertionFailure("ContentView not set")
            return
        }

        guard case let AttachmentContent.view(view, size) = self.content else {
            return
        }

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = true

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: contentView.frame.height),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])

        switch size {
        case .fullWidth, .matchContent, .percent:
            NSLayoutConstraint.activate([
                contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        case let .fixed(width):
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(equalToConstant: width)
            ])
        case let .range(minWidth, maxWidth):
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth),
                contentView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
            ])
        }
    }

    @objc
    func removeFromSuperview() {
        view?.removeFromSuperview()
    }

    /// Causes invalidation of layout of the attachment when the containing view bounds are changed
    /// - Parameter bounds: Updated bounds
    /// - SeeAlso:
    /// `BoundsObserving`
    public func didChangeBounds(_ bounds: CGRect, oldBounds: CGRect) {
        // check how view.bounds can be checked against attachment.bounds
        guard oldBounds != .zero else { return }
        invalidateLayout()
    }

    /// Removes this attachment from the `EditorView` it is contained in.
    public func removeFromContainer() {
        guard let containerTextView = containerTextView,
              let range = containerTextView.attributedText.rangeFor(attachment: self)
        else { return }
        
        containerTextView.textStorage.replaceCharacters(in: range, with: "")
        // Set the selected range in container to show the cursor at deleted location
        // after attachment is removed.
        containerTextView.selectedRange = NSRange(location: range.location, length: 0)
    }

    /// Range of this attachment in it's container
    public func rangeInContainer() -> NSRange? {
        guard let charIndex = indexInContainer else { return nil }
        return NSRange(location: charIndex, length: 1)
    }

    /// Invoked when attributes are added in the containing `EditorView` in the range of string in which this attachment is contained.
    /// - Parameters:
    ///   - range: Affected range
    ///   - attributes: Attributes applied
    open func addedAttributesOnContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key: Any]) {

    }

    // Invoked when attributes are removed in the containing `EditorView` in the range of string in which this attachment is contained.
    /// - Parameters:
    ///   - range: Affected range
    ///   - attributes: Attributes removed
    open func removedAttributesFromContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key]) {

    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Returns the calculated bounds for the attachment based on size rule and content view provided during initialization.
    /// - Parameters:
    ///   - textContainer: Text container for attachment
    ///   - lineFrag: Line fragment containing the attachment
    ///   - position: Position in the text container.
    ///   - charIndex: Character index
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        self.indexInContainer = charIndex

        // When calculating size of EditorView, this may be called on the background thread. Since size of attachment depends on contained view,
        // we need to put the bounds calculation back on main.
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync {
                attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
            }
        }

        guard let textContainer = textContainer,
              textContainer.size.height > 0,
              textContainer.size.width > 0
        else { return .zero }

        if isImageBasedAttachment {
            cachedBounds = bounds
            return bounds
        }

        guard case let AttachmentContent.view(view, attachmentSize) = self.content,
              let containerEditorView = containerEditorView,
              containerEditorView.bounds.size != .zero else {
            return self.frame ?? bounds
        }

        if let cachedBounds = cachedBounds,
            (cachedContainerSize == containerEditorView.bounds.size) {
            cachedContainerSize = containerEditorView.bounds.size
            return cachedBounds
        }

        let indent: CGFloat
        if charIndex < containerEditorView.contentLength {
            let paraStyle = containerEditorView.attributedText.attribute(.paragraphStyle, at: charIndex, effectiveRange: nil) as? NSParagraphStyle
            indent = paraStyle?.firstLineHeadIndent ?? 0
        } else {
            indent = 0
        }

        // Calculate lineFragmentPadding based on containerEditorView. Using passed-in `textContainer` may result in
        // incorrect width if bounds are calculated directly on `attributedText` instead of using `textView`.
        let lineFragmentPadding = containerEditorView.richTextView.textContainer.lineFragmentPadding
        // Account for text leading and trailing margins within the textContainer
        let horizontalTextInsets = (containerEditorView.textContainerInset.left + containerEditorView.textContainerInset.right)
        let adjustedContainerSize = CGSize(
            width: containerEditorView.bounds.size.width - (lineFragmentPadding * 2) - indent - horizontalTextInsets,
            height: containerEditorView.bounds.size.height
        )
        let adjustedLineFrag = CGRect(
            x: lineFrag.origin.x + containerEditorView.textContainerInset.left,
            y: lineFrag.origin.y,
            width: min(lineFrag.size.width, adjustedContainerSize.width),
            height: lineFrag.height
        )

        var size: CGSize

        if let boundsProviding = contentView as? DynamicBoundsProviding {
            size = boundsProviding.sizeFor(attachment: self, containerSize: adjustedContainerSize, lineRect: adjustedLineFrag)
        } else {
            if let contentViewSize = contentView?.bounds.integral.size,
               contentViewSize != .zero {
                size = contentViewSize
            } else {
                size = view.bounds.integral.size
            }

            if (size.width == 0 || size.height == 0),
               let fittingSize = contentView?.systemLayoutSizeFitting(adjustedContainerSize) {
                size = fittingSize
            }

            switch attachmentSize {
            case .matchContent:
                break
            case let .fixed(width):
                size.width = width
            case .fullWidth:
                size.width = adjustedContainerSize.width
            case let .range(minWidth, maxWidth):
                size.width = max(minWidth, min(maxWidth, size.width))
            case let .percent(value):
                size.width = adjustedContainerSize.width * (value / 100.0)
            }
        }

        let offset = offsetProvider?.offset(for: self, in: textContainer, proposedLineFragment: adjustedLineFrag, glyphPosition: position, characterIndex: charIndex) ?? .zero

        self.bounds = CGRect(origin: offset, size: size)
        cachedBounds = self.bounds
        cachedContainerSize = containerEditorView.bounds.size
        var frame = self.frame?.offsetBy(dx: offset.x, dy: offset.y)
        frame?.size = bounds.size

        self.frame = frame ?? view.frame
        return self.bounds
    }

    public func update(with image: AttachmentImage) {
        self.contentView?.removeFromSuperview()
        setup(image: image)
        guard let range = rangeInContainer() else { return }
        let attributes = containerEditorView?.attributedText.attributes(at: range.location, effectiveRange: nil) ?? self.attributes
        containerEditorView?.replaceCharacters(in: range, with: stringWithAttributes(attributes: attributes))
    }

    public func update(_ contentView: AttachmentView, size: AttachmentSize) {
        self.contentView?.removeFromSuperview()
        setup(contentView: contentView, size: size)
        invalidateLayout()
    }

    open func getFullTextRangeIdentificationAttributes() -> [NSAttributedString.Key: Any] {
        [NSAttributedString.Key.viewOnly: name?.rawValue ?? "<no-name>"]
    }

    func setContainerEditor(_ editor: EditorView) {
        self.containerEditorView = editor
    }

    func render(in editorView: EditorView) {
        setContainerEditor(editorView)
        guard let view = view,
            view.superview == nil else { return }
        editorView.richTextView.addSubview(view)

        if var editorContentView = contentView as? EditorContentView,
           editorContentView.delegate == nil {
            editorContentView.delegate = editorView.delegate
        }
    }

    func stringWithAttributes(attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let string = NSMutableAttributedString(attachment: self)
        string.addAttributes(attributes, range: string.fullRange)
        return string
    }
}

extension Attachment {
    /// Invalidates the current layout and triggers a layout update.
    public func invalidateLayout() {
        guard let editor = containerEditorView,
              let range = editor.attributedText.rangeFor(attachment: self)
        else { return }
        cachedBounds = nil
        editor.invalidateLayout(for: range)

        if containerTextView?.isScrollEnabled == false {
            containerTextView?.invalidateIntrinsicContentSize()
        }
    }
}

extension UIView {
    var attachmentContentView: AttachmentContentView? {
        containerAttachmentFor(view: self)
    }

    private func containerAttachmentFor(view: UIView?) -> AttachmentContentView? {
        guard view != nil else { return nil }
        guard let attachmentView = view as? AttachmentContentView else {
            return containerAttachmentFor(view: view?.superview)
        }
        return attachmentView
    }
}
