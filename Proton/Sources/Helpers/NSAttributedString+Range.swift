//
//  NSAttributedStringExtensions.swift
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

public extension NSAttributedString {

    /// Full range of this attributed string.
    var fullRange: NSRange {
        return NSRange(location: 0, length: length)
    }

    /// Collection of all the attachments with containing ranges in this attributed string.
    var attachmentRanges: [(attachment: Attachment, range: NSRange)] {
        var ranges = [(Attachment, NSRange)]()

        let fullRange = NSRange(location: 0, length: self.length)
        self.enumerateAttribute(.attachment, in: fullRange) { value, range, _ in
            if let attachment = value as? Attachment {
                ranges.append((attachment, range))
            }
        }
        return ranges
    }

    /// Range of given attachment in this attributed string.
    /// - Parameter attachment: Attachment to find. Nil if given attachment does not exists in this attributed string.
    func rangeFor(attachment: Attachment) -> NSRange? {
        return attachmentRanges.reversed().first(where: { $0.attachment == attachment })?.range
    }

    /// Ranges of `CharacterSet` in this attributed string.
    /// - Parameter characterSet: CharacterSet to search.
    func rangesOf(characterSet: CharacterSet) -> [NSRange] {
        return string.rangesOf(characterSet: characterSet).map { string.makeNSRange(from: $0) }
    }

    /// Attributed substring in reverse direction.
    /// - Parameter range: Range for substring. Substring starts from location in range to number of characters towards beginning per length
    /// specified in range.
    func reverseAttributedSubstring(from range: NSRange) -> NSAttributedString? {
        guard length > 0 && range.location + range.length < length else {
            return nil
        }
        return attributedSubstring(from: NSRange(location: range.location - range.length, length: range.length))
    }

    /// Gets the next range of attribute starting at the given location in direction based on reverse lookup flag
    /// - Parameters:
    ///   - attribute: Name of the attribute to look up
    ///   - location: Starting location
    ///   - reverseLookup: When true, look up is carried out in reverse direction. Default is false.
    func rangeOf(attribute: NSAttributedString.Key, startingLocation location: Int, reverseLookup: Bool = false) -> NSRange? {
        let range = reverseLookup ? NSRange(location: 0, length: location) : NSRange(location: location, length: length - location)
        let options = reverseLookup ? EnumerationOptions.reverse : []

        var attributeRange: NSRange? = nil
        enumerateAttribute(attribute, in: range, options: options) { val, attrRange, stop in
            if val != nil {
                attributeRange = attrRange
                stop.pointee = true
            }
        }

        return attributeRange
    }

    /// Gets the complete range of attribute at the given location. The attribute is looked up in both forward and
    /// reverse direction and a combined range is returned.  Nil if the attribute does not exist in the given location
    /// - Parameters:
    ///   - attribute: Attribute to search
    ///   - location: Location to inspect
    func rangeOf(attribute: NSAttributedString.Key, at location: Int) -> NSRange? {
        guard location < length,
            self.attribute(attribute, at: location, effectiveRange: nil) != nil else { return nil }

        let forwardRange = rangeOf(attribute: attribute, startingLocation: location, reverseLookup: false)
        let reverseRange = rangeOf(attribute: attribute, startingLocation: location, reverseLookup: true)

        let range: NSRange?
        switch (reverseRange,  forwardRange) {
        case let (.some(r), .some(f)):
            range = NSRange(location: r.location, length: r.length + f.length)
        case let (.none, .some(f)):
            range = f
        case let (.some(r), .none):
            range = r
        default:
            range = nil
        }
        return range
    }

    /// Gets the value of attribute at the given location, if present.
    /// - Parameters:
    ///   - attributeKey: Name of the attribute
    ///   - location: Location to check
    func attributeValue<T>(for attributeKey: NSAttributedString.Key, at location: Int) -> T? {
        guard location < length else { return nil }
        return attribute(attributeKey, at: location, effectiveRange: nil) as? T
    }
}
