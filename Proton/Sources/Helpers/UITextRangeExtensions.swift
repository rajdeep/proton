//
//  UITextRangeExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public extension UITextRange {
    func toNSRange(in input: UITextInput) -> NSRange? {
        let location = input.offset(from: input.beginningOfDocument, to: start)
        let length = input.offset(from: start, to: end)
        return NSRange(location: location, length: length)
    }
}
