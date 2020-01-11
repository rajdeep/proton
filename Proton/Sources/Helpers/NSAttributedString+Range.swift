//
//  NSAttributedStringExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public extension NSAttributedString {
    var fullRange: NSRange {
        return NSRange(location: 0, length: length)
    }

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

    func rangeFor(attachment: Attachment) -> NSRange? {
        for (viewAttachment, range) in attachmentRanges.reversed() {
            if viewAttachment == attachment {
                return range
            }
        }
        return nil
    }
}
