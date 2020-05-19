//
//  LayoutManager.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/5/20.
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

class LayoutManager: NSLayoutManager {
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        guard let textStorage = textStorage,
            let currentCGContext = UIGraphicsGetCurrentContext(),
            let backgroundStyle = textStorage.attribute(.backgroundStyle, at: charRange.location, effectiveRange: nil) as? BackgroundStyle else {
                super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
                return
        }

        let cornerRadius = backgroundStyle.cornerRadius

        let corners = getCornersForBackground(textStorage: textStorage, for: charRange)

        for i in 0..<rectCount  {
            let rect = rectArray[i]
            let rectanglePath = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            color.set()

            if let shadowStyle = backgroundStyle.shadow {
                currentCGContext.setShadow(offset: shadowStyle.offset, blur: shadowStyle.blur, color: shadowStyle.color.cgColor)
            }

            currentCGContext.setAllowsAntialiasing(true)
            currentCGContext.setShouldAntialias(true)

            currentCGContext.setFillColor(color.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.drawPath(using: .fill)
        }
    }

    private func getCornersForBackground(textStorage: NSTextStorage, for charRange: NSRange) -> UIRectCorner {
        let isFirst = (charRange.location == 0)
            || (textStorage.attribute(.backgroundStyle, at: charRange.location - 1, effectiveRange: nil) == nil)

        let isLast = (charRange.endLocation == textStorage.length) ||
            (textStorage.attribute(.backgroundStyle, at: charRange.location + charRange.length, effectiveRange: nil) == nil)

        var corners = UIRectCorner()
        if isFirst {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
        }

        if isLast {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
        }

        return corners
    }
}
