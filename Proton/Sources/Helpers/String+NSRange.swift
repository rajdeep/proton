//
//  String+NSRange.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 18/1/20.
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

public extension String {

    /// Converts given Range to NSRange in this string.
    /// - Parameter range: Range to convert.
    func makeNSRange(from range: Range<String.Index>) -> NSRange {
        let range = range.lowerBound ..< min(range.upperBound, endIndex)

        guard let from = range.lowerBound.samePosition(in: utf16),
            let to = range.upperBound.samePosition(in: utf16) else {
                return NSRange(location: NSNotFound, length: 0)
        }

        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }

    /// Created String Range from given NSRange. Returns nil if range cannot be converted.
    /// - Parameter range: Range to convert.
    func rangeFromNSRange(range: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: range.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(utf16.startIndex, offsetBy: range.location + range.length, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
    }

    /// Returns ranges of given CharacterSet in this string.
    /// - Parameter characterSet: CharacterSet to find.
    func rangesOf(characterSet: CharacterSet) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()
        var newlineRange = rangeOfCharacter(from: characterSet, options: [], range: nil)
        while newlineRange != nil {
            guard let range = newlineRange else { break }
            ranges.append(range)
            newlineRange = rangeOfCharacter(from: characterSet, options: [], range: range.upperBound ..< endIndex)
        }
        return ranges
    }
}
