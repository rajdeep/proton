//
//  EditorAttachment.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

/// Describes an object (typically attachment view) that may change size during the layout pass
public protocol DynamicBoundsProviding: AnyObject {
    func sizeFor(containerSize: CGSize, lineRect: CGRect) -> CGSize
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

class AttachmentContentView: UIView {
    let name: EditorContent.Name
    weak var attachment: Attachment?

    init(name: EditorContent.Name, frame: CGRect) {
        self.name = name
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// An attachment can be used as a container for any view object. Based on the `AttachmentSize` provided, the attachment automatically renders itself alongside the text in `EditorView`.
/// `Attachment` also provides helper functions like `deleteFromContainer` and `rangeInContainer`
open class Attachment: NSTextAttachment, BoundsObserving {

    private let view: AttachmentContentView
    private let size: AttachmentSize

    /// Governs if the attachment should be selected before being deleted. When `true`, tapping the backspace key the first time on range containing `Attachment` will only
    /// select the attachment i.e. show as highlighted. Tapping the backspace again will delete the attachment. If the value is `false`, the attachment will be deleted on the first backspace itself.
    public var selectBeforeDelete = false

    var isBlockAttachment: Bool? {
        if let _ = contentView as? BlockContent {
            return true
        } else if let _ = contentView as? InlineContent {
            return false
        } else {
            return nil
        }
    }

    var name: EditorContent.Name? {
        return (contentView as? EditorContentIdentifying)?.name
    }

    var isRendered: Bool {
        return view.superview != nil
    }

    private let selectionView = SelectionView()

    var isSelected: Bool = false {
        didSet {
            if isSelected {
                selectionView.addTo(parent: view)
            } else {
                selectionView.removeFromSuperview()
            }
        }
    }

    var spacer: NSAttributedString {
        let spacer = isBlockAttachment == true ? "\n" : " "
        return NSAttributedString(string: spacer)
    }

    func stringWithSpacers(appendPrev: Bool, appendNext: Bool) -> NSAttributedString {
        let updatedString = NSMutableAttributedString()
//        if appendPrev {
//            updatedString.append(spacer)
//        }
        updatedString.append(string)
        if appendNext {
            updatedString.append(spacer)
        }
        return updatedString
    }

    public var string: NSAttributedString {
        guard let isBlockAttachment = isBlockAttachment else { return NSAttributedString(string: "<UNKNOWN CONTENT TYPE>") }
//        let key = isBlockAttachment == true ? NSAttributedString.Key.contentType: NSAttributedString.Key.inlineContentType
        let string = NSMutableAttributedString(attachment: self)
        let value = name ?? EditorContent.Name.unknown
        string.addAttributes([
            .contentType: value,
            .isBlockAttachment: isBlockAttachment,
            .isInlineAttachment: !isBlockAttachment
        ], range: string.fullRange)
        return string
    }

    final var frame: CGRect {
        get { view.frame }
        set {
            guard view.frame.equalTo(newValue) == false else { return }

            view.frame = newValue
            containerTextView?.invalidateIntrinsicContentSize()
        }
    }

    public private(set) var containerEditorView: EditorView?

    public var containerContentName: EditorContent.Name? {
        return containerEditorView?.contentName
    }

    private var containerTextView: RichTextView? {
        return containerEditorView?.richTextView
    }

    public func didChangeBounds(_ bounds: CGRect) {
        invalidateLayout()
    }

    var contentView: UIView? {
        get { view.subviews.first }
        set {
            view.subviews.forEach { $0.removeFromSuperview() }
            if let contentView = newValue {
                view.addSubview(contentView)
            }
        }
    }

    public var containerBounds: CGRect? {
        return containerTextView?.bounds
    }

    public override var bounds: CGRect {
        didSet { view.bounds = bounds }
    }

    // This cannot be made convenience init as it prevents this being called from a class that inherits from `Attachment`
    public init<AttachmentView: UIView & BlockContent>(_ contentView: AttachmentView, size: AttachmentSize) {
        self.view = AttachmentContentView(name: contentView.name, frame: contentView.frame)
        self.size = size
        super.init(data: nil, ofType: nil)
        // TODO: revisit - can this be done differently i.e. not setting afterwards
        self.view.attachment = self
        initialize(contentView: contentView)
    }

    // This cannot be made convenience init as it prevents this being called from a class that inherits from `Attachment`
    public init<AttachmentView: UIView & InlineContent>(_ contentView: AttachmentView, size: AttachmentSize) {
        self.view = AttachmentContentView(name: contentView.name, frame: contentView.frame)
        self.size = size
        super.init(data: nil, ofType: nil)
        // TODO: revisit - can this be done differently i.e. not setting afterwards
        self.view.attachment = self
        initialize(contentView: contentView)
    }

    private func initialize(contentView: AttachmentView) {
        self.contentView = contentView
        setup()
        self.bounds = contentView.bounds

        // Required to disable rendering of default attachment image on iOS 13+
        self.image = UIColor.clear.image()
    }

    /// Offsets for the attachment. Can be used to align attachment with the text. Defaults to `.zero`
    public weak var offsetProvider: AttachmentOffsetProviding?

    private func setup() {
        guard let contentView = contentView else {
            assertionFailure("ContentView not set")
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

    func removeFromSuperView() {
        view.removeFromSuperview()
    }

    public func removeFromContainer() {
        guard let containerTextView = containerTextView,
        let range = containerTextView.attributedText.rangeFor(attachment: self) else {
            return
        }
        containerTextView.textStorage.replaceCharacters(in: range, with: "")
    }

    public func rangeInContainer() -> NSRange? {
        guard let containerTextView = containerTextView else {
            return nil
        }
        return containerTextView.attributedText.rangeFor(attachment: self)
    }

    open func addedAttributesOnContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key: Any]) {

    }

    open func removedAttributesFromContainingRange(rangeInContainer range: NSRange, attributes: [NSAttributedString.Key]) {

    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let textContainer = textContainer else { return .zero }

        var size: CGSize

        if let boundsProviding = contentView as? DynamicBoundsProviding {
            size = boundsProviding.sizeFor(containerSize: textContainer.size, lineRect: lineFrag)
        } else {
            size = contentView?.bounds.integral.size ?? view.bounds.integral.size
        }

        if size == .zero,
            let fittingSize = contentView?.systemLayoutSizeFitting(textContainer.size) {
            size = fittingSize
        }

        switch self.size {
        case .matchContent:
            size = contentView?.bounds.integral.size ?? view.bounds.integral.size
        case let .fixed(width):
            size = CGSize(width: min(size.width, width), height: size.height)
        case .fullWidth:
            let containerWidth = textContainer.size.width
            // Account for text leading and trailing margins within the textContainer
            let adjustedContainerWidth = containerWidth - (textContainer.lineFragmentPadding * 2)
            size = CGSize(width: adjustedContainerWidth, height: size.height)
        case let .range(minWidth, maxWidth):
            if size.width < minWidth {
                size = CGSize(width: minWidth, height: size.height)
            } else if size.width > maxWidth {
                size = CGSize(width: maxWidth, height: size.height)
            }
        case let .percent(value):
            let containerWidth = textContainer.size.width
            let adjustedContainerWidth = containerWidth - (textContainer.lineFragmentPadding * 2)
            let percentWidth = adjustedContainerWidth * (value / 100.0)
            size = CGSize(width: percentWidth, height: size.height)
        }

        let offset = offsetProvider?.offset(for: self, in: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex) ?? .zero

        self.bounds = CGRect(origin: offset, size: size)
        return self.bounds
    }

    func render(in editorView: EditorView) {
        self.containerEditorView = editorView
        guard view.superview == nil else { return }
        editorView.richTextView.addSubview(self.view)
        self.view.layoutIfNeeded()

        if var editorContentView = contentView as? EditorContentView,
            editorContentView.delegate == nil {
            editorContentView.delegate = editorView.delegate
        }
    }
}

extension Attachment {
    /// Invalidates the current layout and triggers a layout update.
    public func invalidateLayout() {
        guard let editor = containerEditorView,
            let range = editor.attributedText.rangeFor(attachment: self) else { return }

        editor.invalidateLayout(for: range)
        editor.relayoutAttachments()
    }
}
