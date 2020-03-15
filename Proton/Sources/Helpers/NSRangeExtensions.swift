//
//  NSRangeExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

extension NSRange {
    public static var zero: NSRange {
        return NSRange(location: 0, length: 0)
    }

    public var firstCharacterRange: NSRange {
        return NSRange(location: location, length: 1)
    }

    public var lastCharacterRange: NSRange {
        return NSRange(location: location + length, length: 1)
    }

    public var nextPosition: NSRange {
        return NSRange(location: location + 1, length: 0)
    }

    public func toTextRange(textInput: UITextInput) -> UITextRange? {
        guard
            let rangeStart = textInput.position(
                from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length)
        else {
            return nil
        }
        return textInput.textRange(from: rangeStart, to: rangeEnd)
    }

    public func isValidIn(_ textInput: UITextInput) -> Bool {
        guard location > 0 else { return false }
        let end = location + length
        let contentLength = textInput.offset(
            from: textInput.beginningOfDocument, to: textInput.endOfDocument)
        return end < contentLength
    }
}
