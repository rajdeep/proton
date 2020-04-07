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
    func enumerateContents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.enumerateContentType(.contentType, defaultIfMissing: .paragraph, in: range) { attributes in
            attributes[.isBlockAttachment] as? Bool != false
        }
    }

    func enumerateInlineContents(in range: NSRange? = nil) -> AnySequence<EditorContent> {
        return self.enumerateContentType(.contentType, defaultIfMissing: .text, in: range) { attributes in
            attributes[.isInlineAttachment] as? Bool != false
        }
    }

    func rangeOfCharacter(from characterSet: CharacterSet) -> NSRange? {
        guard let range = string.rangeOfCharacter(from: characterSet) else {
            return nil
        }
        return string.makeNSRange(from: range)
    }
}

extension NSAttributedString {
    func enumerateContentType(_ type: NSAttributedString.Key, defaultIfMissing: EditorContent.Name, in range: NSRange? = nil, where filter: @escaping ((RichTextAttributes) -> Bool) = { _ in return true}) -> AnySequence<EditorContent> {
        let range = range ?? self.fullRange
        let contentString = self.attributedSubstring(from: range)
        return AnySequence { () -> AnyIterator<EditorContent> in
            var substringRange = NSRange(location: 0, length: contentString.length)

            return AnyIterator {
                guard substringRange.location <= contentString.length else {
                    return nil
                }

                var content: EditorContent?
                
                contentString.enumerateAttribute(type, in: substringRange, options: [.longestEffectiveRangeNotRequired]) { (name, range, stop) in
                    let contentName = name as? EditorContent.Name ?? defaultIfMissing
                    let substring = contentString.attributedSubstring(from: range)
                    stop.pointee = true
                    if contentName == EditorContent.Name.viewOnly {
                        content = EditorContent(type: .viewOnly, enclosingRange: range)
                    } else if let attachment = substring.attribute(.attachment, at: 0, effectiveRange: nil) as? Attachment {
                        if let contentView = attachment.contentView {
                            let isBlockAttachment = substring.attribute(.isBlockAttachment, at: 0, effectiveRange: nil) as? Bool
                            let attachmentType = (isBlockAttachment == true) ? AttachmentType.block : .inline
                            content = EditorContent(type: .attachment(name: contentName, attachment: attachment, contentView: contentView, type: attachmentType), enclosingRange: range)
                        }
                    } else {
                        let contentSubstring = NSMutableAttributedString(attributedString: substring)
                        content = EditorContent(type: .text(name: contentName, attributedString: contentSubstring), enclosingRange: range)
                    }

                    let location = range.location + range.length
                    substringRange = NSRange(location: location, length: contentString.length - location)
                }

                return content
            }
        }
    }
}
