//
//  TextStorage.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
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

protocol DefaultTextFormattingProviding: AnyObject {
    var font: UIFont { get }
    var paragraphStyle: NSMutableParagraphStyle { get }
    var textColor: UIColor { get }
}

class TextStorage: NSTextStorage {

    let storage = NSTextStorage()

    let defaultParagraphStyle = NSParagraphStyle()
    let defaultFont = UIFont.preferredFont(forTextStyle: .body)
    var defaultTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    weak var defaultTextFormattingProvider: DefaultTextFormattingProviding?

    var textEndRange: NSRange {
        return NSRange(location: length, length: 0)
    }

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

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
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
        let attachmentsToDelete = getAttachments(in: range)
        storage.replaceCharacters(in: range, with: str)
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedCharacters, .editedAttributes], range: range, changeInLength: delta)
        endEditing()
        attachmentsToDelete.forEach { $0.removeFromSuperView() }
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        let updatedAttributes = applyingDefaultFormattingIfRequired(attrs)
        storage.setAttributes(updatedAttributes, range: range)
        storage.rangesOf(characterSet: .newlines)
            .forEach { storage.addAttribute(.contentType, value: EditorContent.Name.newline, range: $0) }
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }

    private func applyingDefaultFormattingIfRequired(_ attributes: RichTextAttributes?) -> RichTextAttributes {
        var updatedAttributes = attributes ?? [:]
        if attributes?[.paragraphStyle] == nil {
            updatedAttributes[.paragraphStyle] = defaultTextFormattingProvider?.paragraphStyle ?? defaultParagraphStyle
        }

        if attributes?[.font] == nil {
            updatedAttributes[.font] = defaultTextFormattingProvider?.font ?? defaultFont
        }

        if attributes?[.foregroundColor] == nil {
            updatedAttributes[.foregroundColor] = defaultTextFormattingProvider?.textColor ?? defaultTextColor
        }

        return updatedAttributes
    }

    override func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        beginEditing()
        storage.addAttributes(attrs, range: range)
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }

    func removeAttributes(_ attrs: [NSAttributedString.Key], range: NSRange) {
        beginEditing()
        attrs.forEach { storage.removeAttribute($0, range: range) }
        fixMissingAttributes(deletedAttributes: attrs, range: range)
        storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
        edited([.editedAttributes], range: range, changeInLength: 0)
        endEditing()
    }

    private func fixMissingAttributes(deletedAttributes attrs: [NSAttributedString.Key], range: NSRange) {
        if attrs.contains(.foregroundColor) {
            storage.addAttribute(.foregroundColor, value: defaultTextColor, range: range)
        }

        if attrs.contains(.paragraphStyle) {
            storage.addAttribute(.paragraphStyle, value: defaultParagraphStyle, range: range)
        }

        if attrs.contains(.font) {
            storage.addAttribute(.font, value: defaultFont, range: range)
        }
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

    private func getAttachments(in range: NSRange) -> [Attachment] {
        var attachments = [Attachment]()
        storage.enumerateAttribute(.attachment,
                                   in: range,
                                   options: .longestEffectiveRangeNotRequired,
                                   using: { (attribute, _, _) in
                                    if let attachment = attribute as? Attachment {
                                        attachments.append(attachment)
                                    }
        })
        return attachments
    }
}
