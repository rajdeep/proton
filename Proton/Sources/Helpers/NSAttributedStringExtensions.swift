//
//  NSAttributedStringExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {
    var fullRange: NSRange {
        return NSRange(location: 0, length: length)
    }
}
