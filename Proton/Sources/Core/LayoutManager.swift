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

protocol LayoutManagerDelegate: AnyObject {
    var typingAttributes: [NSAttributedString.Key: Any] { get }
    var selectedRange: NSRange { get }
    var paragraphStyle: NSMutableParagraphStyle? { get }
    var font: UIFont? { get }
    var textColor: UIColor? { get }

    var sequenceGenerators: [SequenceGenerator] { get }
    var listLineFormatting: LineFormatting { get }
}

class LayoutManager: NSLayoutManager {

    private let defaultBulletColor = UIColor.black

    weak var layoutManagerDelegate: LayoutManagerDelegate?

    private var bitmaps = [NSAttributedString: UIImage]()

    private var sequenceGenerators: [SequenceGenerator] {
        let sequenceGenerators = layoutManagerDelegate?.sequenceGenerators ?? []
        guard sequenceGenerators.isEmpty == false else {
            return [NumericSequenceGenerator()]
        }
        return sequenceGenerators
    }

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = self.textStorage else { return }

        textStorage.enumerateAttribute(.listItem, in: textStorage.fullRange, options: []) { (value, range, _) in
            if value != nil {
                drawListMarkers(textStorage: textStorage, listRange: range)
            }
        }
    }

    var defaultParagraphStyle: NSParagraphStyle {
        return layoutManagerDelegate?.paragraphStyle ?? NSParagraphStyle()
    }

    private func drawListMarkers(textStorage: NSTextStorage, listRange: NSRange) {
        var lastLayoutRect: CGRect?
        var lastLayoutParaStyle: NSParagraphStyle?
        var lastLayoutFont: UIFont?

        var counters = [Int: Int]()
        var previousLevel = 1

        let defaultFont = self.layoutManagerDelegate?.font ?? UIFont.preferredFont(forTextStyle: .body)
        let listIndent = layoutManagerDelegate?.listLineFormatting.indentation ?? 25.0

        enumerateLineFragments(forGlyphRange: listRange) { (rect, usedRect, textContainer, glyphRange, stop) in
            var newLineRange = NSRange.zero
            if glyphRange.location > 0 {
                newLineRange.location = glyphRange.location - 1
                newLineRange.length = 1
            }

            // Determines if previous line is completed i.e. terminates with a newline char. Absence of newline character means that the
            // line is wrapping and rendering the number/bullet should be skipped.
            var isPreviousLineComplete = true

            if newLineRange.length > 0 {
                isPreviousLineComplete = textStorage.attributedSubstring(from: newLineRange).string == "\n"
            }

            if isPreviousLineComplete {
                let font = textStorage.attribute(.font, at: glyphRange.location, effectiveRange: nil) as? UIFont ?? defaultFont

                let paraStyle = textStorage.attribute(.paragraphStyle, at: glyphRange.location, effectiveRange: nil) as? NSParagraphStyle ?? self.defaultParagraphStyle
                let level = Int(paraStyle.firstLineHeadIndent/listIndent)
                var index = (counters[level] ?? 0)
                counters[level] = index + 1

                // reset index counter for level when list indentation (level) changes.
                if level > previousLevel, level > 1 {
                    index = 0
                    counters[level] = 1
                }

                previousLevel = level
                if level > 0 {
                    self.drawListItem(level: level, index: index, rect: rect, paraStyle: paraStyle, font: font)
                }

                // TODO: should this be moved inside level > 0 check above?
                lastLayoutParaStyle = paraStyle
                lastLayoutRect = rect
                lastLayoutFont = font
            }
        }

        guard let lastRect = lastLayoutRect,
            textStorage.length > 1,
            textStorage.attributedSubstring(from: NSRange(location: listRange.endLocation - 1, length: 1)).string == "\n",
            let paraStyle = lastLayoutParaStyle  else { return }

        if textStorage.length > listRange.endLocation {
            let para = textStorage.attribute(.paragraphStyle, at: listRange.endLocation, effectiveRange: nil) as? NSParagraphStyle
            if para?.firstLineHeadIndent == 0 {
                return
            }
        }

        let level = Int(paraStyle.firstLineHeadIndent/listIndent)
        var index = (counters[level] ?? 0)
        let origin = CGPoint(x: lastRect.minX, y: lastRect.maxY)

        let newLineRect = CGRect(origin: origin, size: lastRect.size)

        if level > previousLevel, level > 1 {
            index = 0
            counters[level] = 1
        }
        previousLevel = level

        let font = lastLayoutFont ?? defaultFont
        drawListItem(level: level, index: index, rect: newLineRect, paraStyle: paraStyle, font: font)
    }

    private func drawListItem(level: Int, index: Int, rect: CGRect, paraStyle: NSParagraphStyle, font: UIFont) {
        guard  level > 0 else {  return }

        let color = layoutManagerDelegate?.textColor ?? self.defaultBulletColor
        color.set()

        let sequenceGenerator = self.sequenceGenerators[(level - 1) % self.sequenceGenerators.count]
        let text = sequenceGenerator.value(at: index)

        let string = NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
        let stringRect = self.rectForBullet(text: string, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)

        if let image = self.bitmaps[string] {
            image.draw(at: stringRect.origin)
        } else {
            let image = self.generateBitmap(string: string, rect: stringRect)
            self.bitmaps[string] = image
            image.draw(at: stringRect.origin)
        }
    }

    private func generateBitmap(string: NSAttributedString, rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { context in
            string.draw(at: .zero)
        }
        return image
    }

    private func rectForBullet(text: NSAttributedString, rect: CGRect, indent: CGFloat, yOffset: CGFloat) -> CGRect {
        let spacerRect = CGRect(origin: CGPoint(x: rect.minX, y: rect.minY + 8), size: CGSize(width: indent, height: rect.height))
        var stringRect = text.boundingRect(with: CGSize(width: indent, height: rect.height), options: [], context: nil)
        stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - stringRect.width, y: spacerRect.minY + yOffset), size: stringRect.size)
        return stringRect
    }

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
