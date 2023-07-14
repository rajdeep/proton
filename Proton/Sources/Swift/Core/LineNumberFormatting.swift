//
//  LineNumberFormatting.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 13/7/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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

public struct Gutter {
    public let lineWidth: CGFloat
    public let lineColor: UIColor?
    public let width: CGFloat
    public let backgroundColor: UIColor

    init(width: CGFloat, backgroundColor: UIColor, lineColor: UIColor? = nil, lineWidth: CGFloat = 1) {
        self.width = width
        self.lineColor = lineColor
        self.lineWidth = (lineColor != nil) ? lineWidth : 0
        self.backgroundColor = backgroundColor
    }
}

public struct LineNumberFormatting {

    public static let `default` = LineNumberFormatting(
        textColor: .darkGray, font: .monospacedDigitSystemFont(ofSize: 17, weight: .light),
        gutter: Gutter(width: 30, backgroundColor: .lightGray))

    public let textColor: UIColor
    public let font: UIFont
    public let gutter: Gutter

    init(textColor: UIColor, font: UIFont, gutter: Gutter) {
        self.textColor = textColor
        self.font = font
        self.gutter = gutter
    }
}
