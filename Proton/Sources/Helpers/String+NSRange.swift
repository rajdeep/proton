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
        let range = range.lowerBound..<min(range.upperBound, endIndex)

        guard let from = range.lowerBound.samePosition(in: utf16),
            let to = range.upperBound.samePosition(in: utf16) else {
                return NSRange(location: NSNotFound, length: 0)
        }

        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }
}
