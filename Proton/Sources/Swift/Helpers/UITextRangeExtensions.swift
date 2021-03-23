//
//  UITextRangeExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
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

public extension UITextRange {

    /// Converts this range to `NSRange`. Returns nil if range cannot be converted.
    /// - Parameter input: Input to use to get range.
    func toNSRange(in input: UITextInput) -> NSRange? {
        let location = input.offset(from: input.beginningOfDocument, to: start)
        let length = input.offset(from: start, to: end)
        return NSRange(location: location, length: length)
    }
}
