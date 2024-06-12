//
//  NSAttributedString+Content.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/1/20.
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

public extension NSAttributedString {

    /// Creates a mutable copy 
    var asMutable: NSMutableAttributedString {
        NSMutableAttributedString(attributedString: self)
    }

    func addingAttributes(_ attributes: [NSAttributedString.Key: Any], to range: NSRange? = nil) -> NSAttributedString {
        let range = range?.clamped(upperBound: length) ?? fullRange
        let mutable = asMutable
        mutable.addAttributes(attributes, range: range)
        return mutable
    }

    /// Enumerates block contents in given range.
    /// - Parameter range: Range to enumerate contents in. Nil to enumerate in entire string.
    func enumerateContents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.enumerateContentType(.blockContentType, options: [], defaultIfMissing: .paragraph, in: range)
    }
    /// Enumerates only inline content in given range.
    /// - Parameter range: Range to enumerate contents in. Nil to enumerate in entire string.
    func enumerateInlineContents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.enumerateContentType(.inlineContentType, options: [.longestEffectiveRangeNotRequired], defaultIfMissing: .text, in: range)
    }

    /// Returns in range of CharacterSet from this string.
    /// - Parameter characterSet: CharacterSet to search.
    func rangeOfCharacter(from characterSet: CharacterSet) -> NSRange? {
        guard let range = string.rangeOfCharacter(from: characterSet) else {
            return nil
        }
        return string.makeNSRange(from: range)
    }


    /// Determines if the given string contains the attributed at provided location
    /// - Parameters:
    ///   - attribute: Attribute to search
    ///   - location: Location for attribute
    /// - Returns: `true` if found, else `false`
    func hasAttribute(_ attribute: NSAttributedString.Key, at location: Int) -> Bool {
        guard location < length else { return false }
        return self.attribute(attribute, at: location, effectiveRange: nil) != nil
    }
}

extension NSAttributedString {
    func enumerateContentType(_ type: NSAttributedString.Key, options: NSAttributedString.EnumerationOptions, defaultIfMissing: EditorContent.Name, in range: NSRange? = nil) -> AnySequence<EditorContent> {
        let range = range ?? self.fullRange
        let contentString = self.attributedSubstring(from: range)
        return AnySequence { () -> AnyIterator<EditorContent> in
            var substringRange = NSRange(location: 0, length: contentString.length)

            return AnyIterator {
                guard substringRange.location <= contentString.length else {
                    return nil
                }

                var content: EditorContent?
                
                contentString.enumerateAttribute(type, in: substringRange, options: options) { (name, range, stop) in
                    let contentName = name as? EditorContent.Name ?? defaultIfMissing
                    let substring = contentString.attributedSubstring(from: range)
                    stop.pointee = true

                    let location = range.location + range.length
                    substringRange = NSRange(location: location, length: contentString.length - location)

                    if contentName == EditorContent.Name.viewOnly {
                        content = EditorContent(type: .viewOnly, enclosingRange: range)
                    } else if let attachment = substring.attribute(.attachment, at: 0, effectiveRange: nil) as? Attachment {
                        if let contentView = attachment.contentView {
                            let isBlockAttachment = substring.attribute(.isBlockAttachment, at: 0, effectiveRange: nil) as? Bool
                            let attachmentType = (isBlockAttachment == true) ? AttachmentType.block : .inline
                            content = EditorContent(type: .attachment(name: contentName, attachment: attachment, contentView: contentView, type: attachmentType), enclosingRange: range)
                        }
                    } else {
                        let location = range.location + range.length
                        substringRange = NSRange(location: location, length: contentString.length - location)

                        let contentSubstring = NSMutableAttributedString(attributedString: substring)
                        // handle successive newlines as single newline element
                        if contentSubstring.rangeOfCharacter(from: .newlines) == NSRange(location: 0, length: 1) {
                            let enclosingRange = NSRange(location: range.location, length: 1)
                            content = EditorContent(type: .text(name: contentName, attributedString: contentSubstring), enclosingRange: enclosingRange)
                            let location = range.location + 1
                            substringRange = NSRange(location: location, length: contentString.length - location)

                        } else {
                            content = EditorContent(type: .text(name: contentName, attributedString: contentSubstring), enclosingRange: range)
                        }
                    }
                }

                return content
            }
        }
    }
}
