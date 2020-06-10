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
    var textContainerInset: UIEdgeInsets { get }

    var listLineFormatting: LineFormatting { get }

    func listMarkerForItem(at index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker
}

class LayoutManager: NSLayoutManager {

    private let defaultBulletColor = UIColor.black

    weak var layoutManagerDelegate: LayoutManagerDelegate?

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = self.textStorage else { return }

        textStorage.enumerateAttribute(.listItem, in: textStorage.fullRange, options: []) { (value, range, _) in
            if value != nil {
                drawListMarkers(textStorage: textStorage, listRange: range, attributeValue: value)
            }
        }
    }

    var defaultParagraphStyle: NSParagraphStyle {
        return layoutManagerDelegate?.paragraphStyle ?? NSParagraphStyle()
    }

    private func drawListMarkers(textStorage: NSTextStorage, listRange: NSRange, attributeValue: Any?) {
        var lastLayoutRect: CGRect?
        var lastLayoutParaStyle: NSParagraphStyle?
        var lastLayoutFont: UIFont?

        var counters = [Int: Int]()
        var previousLevel = 0

        let defaultFont = self.layoutManagerDelegate?.font ?? UIFont.preferredFont(forTextStyle: .body)
        let listIndent = layoutManagerDelegate?.listLineFormatting.indentation ?? 25.0

        var prevStyle: NSParagraphStyle?

        if listRange.location > 0,
            textStorage.attribute(.listItem, at: listRange.location - 1, effectiveRange: nil) != nil {
            prevStyle = textStorage.attribute(.paragraphStyle, at: listRange.location - 1, effectiveRange: nil) as? NSParagraphStyle
        }

        var levelToSet = 0
        textStorage.enumerateAttribute(.paragraphStyle, in: listRange, options: []) { value, range, _ in
            levelToSet = 0
            if let paraStyle = (value as? NSParagraphStyle)?.mutableParagraphStyle {
                let previousLevel = Int(prevStyle?.firstLineHeadIndent ?? 0)/Int(listIndent)
                let currentLevel = Int(paraStyle.firstLineHeadIndent)/Int(listIndent)

                if currentLevel - previousLevel > 1 {
                    levelToSet = previousLevel + 1
                    let indentation = CGFloat(levelToSet) * listIndent
                    paraStyle.firstLineHeadIndent = indentation
                    paraStyle.headIndent = indentation
                    textStorage.addAttribute(.paragraphStyle, value: paraStyle, range: range)
                    prevStyle = paraStyle
                } else {
                    prevStyle = value as? NSParagraphStyle
                }
            }
        }

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

                if level > 0 {
                    self.drawListItem(level: level, previousLevel: previousLevel, index: index, rect: rect, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
                }
                previousLevel = level

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

        var para: NSParagraphStyle?
        if textStorage.length > listRange.endLocation {
            para = textStorage.attribute(.paragraphStyle, at: listRange.endLocation, effectiveRange: nil) as? NSParagraphStyle
            if para?.firstLineHeadIndent == 0 {
                return
            }
        }

        // get the para style from last location of text or next. Use next if available as the indent level could be changing
        // and the text bullet needs to be drawn for that level. If the text location is already at the end, then use the same indent level
        let paraStyleForLastRect = para ?? paraStyle

        let level = Int(paraStyleForLastRect.firstLineHeadIndent/listIndent)
        var index = (counters[level] ?? 0)
        let origin = CGPoint(x: lastRect.minX, y: lastRect.maxY)

        let newLineRect = CGRect(origin: origin, size: lastRect.size)

        if level > previousLevel, level > 1 {
            index = 0
            counters[level] = 1
        }
        previousLevel = level

        let font = lastLayoutFont ?? defaultFont
        drawListItem(level: level, previousLevel: previousLevel, index: index, rect: newLineRect, paraStyle: paraStyleForLastRect, font: font, attributeValue: attributeValue)
    }

    private func drawListItem(level: Int, previousLevel: Int, index: Int, rect: CGRect, paraStyle: NSParagraphStyle, font: UIFont, attributeValue: Any?) {
        guard  level > 0 else {  return }

        let color = layoutManagerDelegate?.textColor ?? self.defaultBulletColor
        color.set()

        let marker = layoutManagerDelegate?.listMarkerForItem(at: index, level: level, previousLevel: previousLevel, attributeValue: attributeValue) ?? .string(NSAttributedString(string: "*"))

        let listMarkerImage: UIImage
        let markerRect: CGRect

        switch marker {
        case let .string(text):
            let markerSize = text.boundingRect(with: CGSize(width: paraStyle.firstLineHeadIndent, height: rect.height), options: [], context: nil).size
            markerRect = rectForBullet(markerSize: markerSize, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)
            listMarkerImage = self.generateBitmap(string: text, rect: markerRect)
        case let .image(image):
            markerRect = rectForBullet(markerSize: image.size, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)
            listMarkerImage = image
        }

        listMarkerImage.draw(at: markerRect.origin)
    }

    private func generateBitmap(string: NSAttributedString, rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { context in
            string.draw(at: .zero)
        }
        return image
    }

    private func rectForBullet(markerSize: CGSize, rect: CGRect, indent: CGFloat, yOffset: CGFloat) -> CGRect {
        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
        let spacerRect = CGRect(origin: CGPoint(x: rect.minX, y: rect.minY + topInset), size: CGSize(width: indent, height: rect.height))
        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSize.width, y: spacerRect.minY + yOffset), size: markerSize)
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
