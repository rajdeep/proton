//
//  String+NSRange.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

public extension String {
    func makeNSRange(from range: Range<String.Index>) -> NSRange {
        let range = range.lowerBound ..< min(range.upperBound, endIndex)

        guard let from = range.lowerBound.samePosition(in: utf16),
            let to = range.upperBound.samePosition(in: utf16) else {
                return NSRange(location: NSNotFound, length: 0)
        }

        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }

    func rangeFromNSRange(range: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: range.location + range.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }

    func rangesOf(characterSet: CharacterSet) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()
        var newlineRange = rangeOfCharacter(from: .newlines, options: [], range: nil)
        while newlineRange != nil {
            guard let range = newlineRange else { break }
            ranges.append(range)
            newlineRange = rangeOfCharacter(from: .newlines, options: [], range: range.upperBound ..< endIndex)
        }
        return ranges
    }
}
