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
        switch contentView {
        case is BlockContent: return true
        case is InlineContent: return false
        default: return nil
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

    /// Attributed string representation of the `Attachment`. This can be used directly to replace a range of text in `EditorView`
    /// ### Usage Example ###
    /// ```
    /// let attachment = Attachment(PanelView(), size: .fullWidth)
    /// let attrString = NSMutableAttributedString(string: "This is a test string")
    /// attrString.append(attachment.string)
    /// editor.attributedText = attrString
    /// ```
    public var string: NSAttributedString {
        guard let isBlockAttachment = isBlockAttachment else { return NSAttributedString(string: "<UNKNOWN CONTENT TYPE>") }
//        let key = isBlockAttachment == true ? NSAttributedString.Key.contentType: NSAttributedString.Key.inlineContentType
        let string = NSMutableAttributedString(attachment: self)
        let value = name ?? EditorContent.Name.unknown
        let contentKey: NSAttributedString.Key = isBlockAttachment ? .blockContentType : .inlineContentType
        string.addAttributes([
            contentKey: value,
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

    /// `EditorView` containing this attachment
    public private(set) weak var containerEditorView: EditorView?

    /// Name of the content for the `EditorView`
    /// - SeeAlso:
    /// `EditorView`
    public var containerContentName: EditorContent.Name? {
        return containerEditorView?.contentName
    }

    private var containerTextView: RichTextView? {
        return containerEditorView?.richTextView
    }

    /// Causes invalidation of layout of the attachment when the containing view bounds are changed
    /// - Parameter bounds: Updated bounds
    /// - SeeAlso:
    /// `BoundsObserving`
    public func didChangeBounds(_ bounds: CGRect) {
        invalidateLayout()
    }

    public var contentView: UIView? {
        get { view.subviews.first }
        set {
            view.subviews.forEach { $0.removeFromSuperview() }
            if let contentView = newValue {
                view.addSubview(contentView)
            }
        }
    }

    /// Bounds of the container
    public var containerBounds: CGRect? {
        return containerTextView?.bounds
    }

    /// The bounds rectangle, which describes the attachment's location and size in its own coordinate system.
    public override var bounds: CGRect {
        didSet { view.bounds = bounds }
    }

    // This cannot be made convenience init as it prevents this being called from a class that inherits from `Attachment`
    /// Initializes the attachment with the given content view
    /// - Parameters:
    ///   - contentView: Content view to be hosted within the attachment
    ///   - size: Size rule for attachment
    public init<AttachmentView: UIView & BlockContent>(_ contentView: AttachmentView, size: AttachmentSize) {
        self.view = AttachmentContentView(name: contentView.name, frame: contentView.frame)
        self.size = size
        super.init(data: nil, ofType: nil)
        // TODO: revisit - can this be done differently i.e. not setting afterwards
        self.view.attachment = self
        initialize(contentView: contentView)
    }

    // This cannot be made convenience init as it prevents this being called from a class that inherits from `Attachment`
    /// Initializes the attachment with the given content view
    /// - Parameters:
    ///   - contentView: Content view to be hosted within the attachment
    ///   - size: Size rule for attachment
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

    /// Removes this attachment from the `EditorView` it is contained in.
    public func removeFromContainer() {
        guard let containerTextView = containerTextView,
        let range = containerTextView.attributedText.rangeFor(attachment: self) else {
            return
        }
        containerTextView.textStorage.replaceCharacters(in: range, with: "")
    }

    /// Range of this attachment in it's container
    public func rangeInContainer() -> NSRange? {
        return containerTextView?.attributedText.rangeFor(attachment: self)
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
         guard let textContainer = textContainer, textContainer.size.height > 0 && textContainer.size.width > 0 else { return .zero }

        var size: CGSize

        if let boundsProviding = contentView as? DynamicBoundsProviding {
            size = boundsProviding.sizeFor(containerSize: textContainer.size, lineRect: lineFrag)
        } else {
            size = contentView?.bounds.integral.size ?? view.bounds.integral.size
        }

        if (size.width == 0 || size.height == 0),
            let fittingSize = contentView?.systemLayoutSizeFitting(textContainer.size) {
            size = fittingSize
        }

        switch self.size {
        case .matchContent:
            break
        case let .fixed(width):
            size = CGSize(width: min(size.width, width), height: size.height)
        case .fullWidth:
            let containerWidth = textContainer.size.width
            // Account for text leading and trailing margins within the textContainer
            let paraStyle = self.containerEditorView?.attributedText.attribute(.paragraphStyle, at: charIndex, effectiveRange: nil) as? NSParagraphStyle
            let indent = paraStyle?.firstLineHeadIndent ?? 0
            let adjustedContainerWidth = containerWidth - (textContainer.lineFragmentPadding * 2) - indent
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
        editor.relayoutAttachments(in: range)
    }
}
