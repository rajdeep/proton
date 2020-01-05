//
//  TextStorage.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

protocol DefaultTextFormattingProviding: class {
    var font: UIFont? { get }
    var paragraphStyle: NSParagraphStyle { get }
}

class TextStorage: NSTextStorage {

    let storage = NSMutableAttributedString()

    private let defaultParagraphStyle = NSParagraphStyle()
    private let defaultFont = UIFont.systemFont(ofSize: 17)

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding?

    override init() {
        super.init()
    }

    override init(attributedString: NSAttributedString) {
        super.init()
        storage.setAttributedString(attributedString)
    }

    @available(*, unavailable, message: "init(itemProviderData:typeIdentifier:) unavailable, use init")
    required init(itemProviderData data: Data, typeIdentifier: String) throws {
        fatalError("init(itemProviderData:typeIdentifier:) has not been implemented")
    }

    @available(*, unavailable, message: "init(coder:) unavailable, use init")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var string: String {
        return storage.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        guard storage.length > location else {
            return [:]
        }

        return storage.attributes(at: location, effectiveRange: range)
    }

    override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        // TODO: Add undo behaviour
        super.replaceCharacters(in: range, with: attrString)
    }

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        let delta = str.utf16.count - range.length

        storage.replaceCharacters(in: range, with: str)
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: delta)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        let updatedAttributes = applyingDefaultFormattingIfRequired(attrs)
        storage.setAttributes(updatedAttributes, range: range)
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }

    private func applyingDefaultFormattingIfRequired(_ attributes: RichTextAttributes?) -> RichTextAttributes {
        var updatedAttributes = attributes ?? [:]
        if attributes?[NSAttributedString.Key.contentType] == nil {
            updatedAttributes[NSAttributedString.Key.paragraphStyle] = defaultTextFormattingProvider?.paragraphStyle ?? defaultParagraphStyle
        }

        if attributes?[NSAttributedString.Key.font] == nil {
            updatedAttributes[NSAttributedString.Key.font] = defaultTextFormattingProvider?.font ?? defaultFont
        }

        return updatedAttributes
    }

    override func addAttributes(_ attrs: [NSAttributedString.Key : Any], range: NSRange) {
        beginEditing()
        storage.addAttributes(attrs, range: range)
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }

    func removeAttributes(_ attrs: [NSAttributedString.Key], range: NSRange) {
        beginEditing()
        for attr in attrs {
            storage.removeAttribute(attr, range: range)
        }
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }

    override func removeAttribute(_ attr: NSAttributedString.Key, range: NSRange) {
        storage.removeAttribute(attr, range: range)
    }

    func insertAttachment(in range: NSRange, attachment: Attachment) {
        let spacer = attachment.spacer.string
        var hasPrevSpacer = false
        if range.length + range.location > 0 {
            hasPrevSpacer = attributedSubstring(from: NSRange(location: max(range.location - 1, 0), length: 1)).string == spacer
        }
        var hasNextSpacer = false
        if (range.location + range.length + 1) <= length {
            hasNextSpacer = attributedSubstring(from: NSRange(location: range.location, length: 1)).string == spacer
        }

        let attachmentString = attachment.stringWithSpacers(appendPrev: !hasPrevSpacer, appendNext: !hasNextSpacer)
        replaceCharacters(in: range, with: attachmentString)
    }

    private func handleDeletedAttachments(in range: NSRange) {
        storage.enumerateAttribute(NSAttributedString.Key.attachment,
                                   in: range,
                                   options: .longestEffectiveRangeNotRequired,
                                   using: { (attribute, _, _) in
                                    if let attachment = attribute as? Attachment {
                                        attachment.removeFromSuperView()
                                    }
        })
    }
}
