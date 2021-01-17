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
    private var counters = [Int: Int]()

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

        var previousLevel = 0

        let defaultFont = self.layoutManagerDelegate?.font ?? UIFont.preferredFont(forTextStyle: .body)
        let listIndent = layoutManagerDelegate?.listLineFormatting.indentation ?? 25.0

        var prevStyle: NSParagraphStyle?

        if listRange.location > 0,
           textStorage.attribute(.listItem, at: listRange.location - 1, effectiveRange: nil) != nil {
            prevStyle = textStorage.attribute(.paragraphStyle, at: listRange.location - 1, effectiveRange: nil) as? NSParagraphStyle
        }

        if prevStyle == nil {
            counters = [:]
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

        let listGlyphRange = glyphRange(forCharacterRange: listRange, actualCharacterRange: nil)
        enumerateLineFragments(forGlyphRange: listGlyphRange) { [weak self] (rect, usedRect, textContainer, glyphRange, stop) in
            guard let self = self else { return }
            let characterRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

            var newLineRange = NSRange.zero
            if characterRange.location > 0 {
                newLineRange.location = characterRange.location - 1
                newLineRange.length = 1
            }

            // Determines if previous line is completed i.e. terminates with a newline char. Absence of newline character means that the
            // line is wrapping and rendering the number/bullet should be skipped.
            var isPreviousLineComplete = true
            var skipMarker = false

            if newLineRange.length > 0 {
                let newLineString = textStorage.substring(from: newLineRange)
                isPreviousLineComplete = newLineString == "\n"
                skipMarker = textStorage.attribute(.skipNextListMarker, at: newLineRange.location, effectiveRange: nil) != nil
            }

            let font = textStorage.attribute(.font, at: characterRange.location, effectiveRange: nil) as? UIFont ?? defaultFont
            let paraStyle = textStorage.attribute(.paragraphStyle, at: characterRange.location, effectiveRange: nil) as? NSParagraphStyle ?? self.defaultParagraphStyle

            if isPreviousLineComplete, skipMarker == false {

                let level = Int(paraStyle.firstLineHeadIndent/listIndent)
                var index = (self.counters[level] ?? 0)
                self.counters[level] = index + 1

                // reset index counter for level when list indentation (level) changes.
                if level > previousLevel, level > 1 {
                    index = 0
                    self.counters[level] = 1
                }

                if level > 0 {
                    self.drawListItem(level: level, previousLevel: previousLevel, index: index, rect: rect, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
                }
                previousLevel = level

                // TODO: should this be moved inside level > 0 check above?
            }
            lastLayoutParaStyle = paraStyle
            lastLayoutRect = rect
            lastLayoutFont = font
        }

        var skipMarker = false

        if textStorage.length > 0 {
            let range = NSRange(location: textStorage.length - 1, length: 1)
            let lastChar = textStorage.substring(from: range)
            skipMarker = lastChar == "\n" && textStorage.attribute(.skipNextListMarker, at: range.location, effectiveRange: nil) != nil
        }

        guard skipMarker == false,
              let lastRect = lastLayoutRect,
              textStorage.length > 1,
              textStorage.substring(from: NSRange(location: listRange.endLocation - 1, length: 1)) == "\n",
              let paraStyle = lastLayoutParaStyle
        else { return }

        let level = Int(paraStyle.firstLineHeadIndent/listIndent)
        var index = (counters[level] ?? 0)
        let origin = CGPoint(x: lastRect.minX, y: lastRect.maxY)

        var para: NSParagraphStyle?
        if textStorage.length > listRange.endLocation {
            para = textStorage.attribute(.paragraphStyle, at: listRange.endLocation, effectiveRange: nil) as? NSParagraphStyle
            let paraLevel = Int((para?.firstLineHeadIndent ?? 0)/listIndent)
            // don't draw last rect if there's a following list item (in another indent level)
            if para != nil, paraLevel != level {
                return
            }
        }

        let newLineRect = CGRect(origin: origin, size: lastRect.size)

        if level > previousLevel, level > 1 {
            index = 0
            counters[level] = 1
        }
        previousLevel = level

        let font = lastLayoutFont ?? defaultFont
        drawListItem(level: level, previousLevel: previousLevel, index: index, rect: newLineRect, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
    }

    private func drawListItem(level: Int, previousLevel: Int, index: Int, rect: CGRect, paraStyle: NSParagraphStyle, font: UIFont, attributeValue: Any?) {
        guard level > 0 else { return }

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

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = textStorage,
              let currentCGContext = UIGraphicsGetCurrentContext()
        else { return }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.backgroundStyle, in: characterRange) { attr, bgStyleRange, _ in
            var rects = [CGRect]()
            if let backgroundStyle = attr as? BackgroundStyle {
                let bgStyleGlyphRange = self.glyphRange(forCharacterRange: bgStyleRange, actualCharacterRange: nil)
                enumerateLineFragments(forGlyphRange: bgStyleGlyphRange) { _, usedRect, textContainer, lineRange, _ in
                    let rangeIntersection = NSIntersectionRange(bgStyleGlyphRange, lineRange)
                    var rect = self.boundingRect(forGlyphRange: rangeIntersection, in: textContainer)
                    // Glyphs can take space outside of the line fragment, and we cannot draw outside of it.
                    // So it is best to restrict the height just to the line fragment.
                    rect.origin.y = usedRect.origin.y
                    rect.size.height = usedRect.height
                    let insetTop = self.layoutManagerDelegate?.textContainerInset.top ?? 0
                    rects.append(rect.offsetBy(dx: 0, dy: insetTop))
                }
                drawBackground(backgroundStyle: backgroundStyle, rects: rects, currentCGContext: currentCGContext)
            }
        }
    }

    private func drawBackground(backgroundStyle: BackgroundStyle, rects: [CGRect], currentCGContext: CGContext) {
        currentCGContext.saveGState()

        let rectCount = rects.count
        let rectArray = rects
        let cornerRadius = backgroundStyle.cornerRadius
        let color = backgroundStyle.color

        for i in 0..<rectCount {
            var previousRect = CGRect.zero
            var nextRect = CGRect.zero

            let currentRect = rectArray[i]

            if i > 0 {
                previousRect = rectArray[i - 1]
            }

            if i < rectCount - 1 {
                nextRect = rectArray[i + 1]
            }

            let corners = calculateCornersForBackground(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)

            let rectanglePath = UIBezierPath(roundedRect: currentRect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            color.set()

            currentCGContext.setAllowsAntialiasing(true)
            currentCGContext.setShouldAntialias(true)

            if let shadowStyle = backgroundStyle.shadow {
                currentCGContext.setShadow(offset: shadowStyle.offset, blur: shadowStyle.blur, color: shadowStyle.color.cgColor)
            }

            currentCGContext.setFillColor(color.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.drawPath(using: .fill)

            let lineWidth = backgroundStyle.border?.lineWidth ?? 0
            let overlappingLine = UIBezierPath()

            // TODO: Revisit shadow drawing logic to simplify a bit

            let leftVerticalJoiningLine = UIBezierPath()
            let rightVerticalJoiningLine = UIBezierPath()
            // Shadow for vertical lines need to be drawn separately to get the perfect alignment with shadow on rectangles.
            let leftVerticalJoiningLineShadow = UIBezierPath()
            let rightVerticalJoiningLineShadow = UIBezierPath()

            if previousRect != .zero, (currentRect.maxX - previousRect.minX) > cornerRadius {
                let yDiff = currentRect.minY - previousRect.maxY
                overlappingLine.move(to: CGPoint(x: max(previousRect.minX, currentRect.minX) + lineWidth/2, y: previousRect.maxY + yDiff/2))
                overlappingLine.addLine(to: CGPoint(x: min(previousRect.maxX, currentRect.maxX) - lineWidth/2, y: previousRect.maxY + yDiff/2))

                let leftX = max(previousRect.minX, currentRect.minX)
                let rightX = min(previousRect.maxX, currentRect.maxX)

                leftVerticalJoiningLine.move(to: CGPoint(x: leftX, y: previousRect.maxY))
                leftVerticalJoiningLine.addLine(to: CGPoint(x: leftX, y: currentRect.minY))

                rightVerticalJoiningLine.move(to: CGPoint(x: rightX, y: previousRect.maxY))
                rightVerticalJoiningLine.addLine(to: CGPoint(x: rightX, y: currentRect.minY))

                let leftShadowX = max(previousRect.minX, currentRect.minX) + lineWidth
                let rightShadowX = min(previousRect.maxX, currentRect.maxX) - lineWidth

                leftVerticalJoiningLineShadow.move(to: CGPoint(x: leftShadowX, y: previousRect.maxY))
                leftVerticalJoiningLineShadow.addLine(to: CGPoint(x: leftShadowX, y: currentRect.minY))

                rightVerticalJoiningLineShadow.move(to: CGPoint(x: rightShadowX, y: previousRect.maxY))
                rightVerticalJoiningLineShadow.addLine(to: CGPoint(x: rightShadowX, y: currentRect.minY))
            }

            if let borderColor = backgroundStyle.border?.color {
                currentCGContext.setLineWidth(lineWidth * 2)
                currentCGContext.setStrokeColor(borderColor.cgColor)

                // always draw vertical joining lines
                currentCGContext.addPath(leftVerticalJoiningLineShadow.cgPath)
                currentCGContext.addPath(rightVerticalJoiningLineShadow.cgPath)

                currentCGContext.drawPath(using: .stroke)
            }

            currentCGContext.setShadow(offset: .zero, blur:0, color: UIColor.clear.cgColor)

            if let borderColor = backgroundStyle.border?.color {
                currentCGContext.setLineWidth(lineWidth)
                currentCGContext.setStrokeColor(borderColor.cgColor)
                currentCGContext.addPath(rectanglePath.cgPath)

                // always draw vertical joining lines
                currentCGContext.addPath(leftVerticalJoiningLine.cgPath)
                currentCGContext.addPath(rightVerticalJoiningLine.cgPath)

                currentCGContext.drawPath(using: .stroke)
            }

            // always draw over the overlapping bounds of previous and next rect to hide shadow/borders
            currentCGContext.setStrokeColor(color.cgColor)
            currentCGContext.addPath(overlappingLine.cgPath)
            // account for the spread of shadow
            let blur = (backgroundStyle.shadow?.blur ?? 1) * 2
            let offsetHeight = abs(backgroundStyle.shadow?.offset.height ?? 1)
            currentCGContext.setLineWidth(lineWidth + (currentRect.minY - previousRect.maxY) + blur + offsetHeight + 1)
            currentCGContext.drawPath(using: .stroke)
        }
        currentCGContext.restoreGState()
    }

    private func calculateCornersForBackground(previousRect: CGRect, currentRect: CGRect, nextRect: CGRect, cornerRadius: CGFloat) -> UIRectCorner {
        var corners = UIRectCorner()

        if previousRect.minX > currentRect.minX {
            corners.formUnion(.topLeft)
        }

        if previousRect.maxX < currentRect.maxX {
            corners.formUnion(.topRight)
        }

        if currentRect.maxX > nextRect.maxX {
            corners.formUnion(.bottomRight)
        }

        if currentRect.minX < nextRect.minX {
            corners.formUnion(.bottomLeft)
        }

        if nextRect == .zero || nextRect.maxX <= currentRect.minX + cornerRadius {
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
        }

        if previousRect == .zero || (currentRect.maxX <= previousRect.minX + cornerRadius) {
            corners.formUnion(.topLeft)
            corners.formUnion(.topRight)
        }

        return corners
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
