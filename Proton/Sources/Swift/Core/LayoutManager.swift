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
    
    var isLineNumbersEnabled: Bool { get }
    var lineNumberFormatting: LineNumberFormatting { get }
    var lineNumberWrappingMarker: String? { get }

    func listMarkerForItem(at index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker
    func lineNumberString(for index: Int) -> String?
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

    var defaultFont: UIFont {
        return layoutManagerDelegate?.font ?? UIFont.preferredFont(forTextStyle: .body)
    }

    private func drawListMarkers(textStorage: NSTextStorage, listRange: NSRange, attributeValue: Any?) {
        var lastLayoutRect: CGRect?
        var lastLayoutParaStyle: NSParagraphStyle?
        var lastLayoutFont: UIFont?

        var previousLevel = 0
        var level = 0

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
        previousLevel = 0
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
            let previousParaStyle: NSParagraphStyle?

            if characterRange.location == 0 {
                previousParaStyle = nil
            } else {
                previousParaStyle  = textStorage.attribute(.paragraphStyle, at: max(characterRange.location - 1, 0), effectiveRange: nil) as? NSParagraphStyle
            }

            let paraStyle = textStorage.attribute(.paragraphStyle, at: characterRange.location, effectiveRange: nil) as? NSParagraphStyle ?? self.defaultParagraphStyle
            previousLevel = Int(previousParaStyle?.firstLineHeadIndent ?? 0)/Int(listIndent)
            if isPreviousLineComplete, skipMarker == false {

                level = Int(paraStyle.firstLineHeadIndent/listIndent)
                var index = (self.counters[level] ?? 0)
                self.counters[level] = index + 1

                // reset index counter for level when list indentation (level) changes.
                if level > previousLevel, level > 1 {
                    index = 0
                    self.counters[level] = 1
                }

                var adjustedRect = rect
                // Account for height of line fragment based on styles defined in paragraph, like paragraphSpacing
                adjustedRect.size.height = usedRect.height
                if level > 0 {
                    self.drawListItem(level: level, previousLevel: previousLevel, index: index, rect: adjustedRect, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
                }

                // TODO: should this be moved inside level > 0 check above?
            }
            lastLayoutParaStyle = paraStyle
            lastLayoutRect = rect
            lastLayoutFont = font
            previousLevel = level
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
        drawListItem(level: level, previousLevel: previousLevel, index: index, rect: newLineRect.integral, paraStyle: paraStyle, font: font, attributeValue: attributeValue)
    }

    private func drawListItem(level: Int, previousLevel: Int, index: Int, rect: CGRect, paraStyle: NSParagraphStyle, font: UIFont, attributeValue: Any?) {
        guard level > 0 else { return }

        let color = layoutManagerDelegate?.textColor ?? self.defaultBulletColor
        color.set()

        let marker = layoutManagerDelegate?.listMarkerForItem(at: index, level: level, previousLevel: previousLevel, attributeValue: attributeValue) ?? .string(NSAttributedString(string: "*"))

        let listMarkerImage: UIImage
        let markerRect: CGRect
//        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
        switch marker {
        case let .string(text):
            let markerSize = text.boundingRect(with: CGSize(width: paraStyle.firstLineHeadIndent, height: rect.height), options: [], context: nil).size
            markerRect = rectForNumberedList(markerSize: markerSize, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)
            listMarkerImage = self.generateBitmap(string: text, rect: markerRect)
        case let .image(image, size):
            markerRect = rectForBullet(markerSize: size, rect: rect, indent: paraStyle.firstLineHeadIndent, yOffset: paraStyle.paragraphSpacingBefore)
            listMarkerImage = image.resizeImage(to: markerRect.size)
        }

//        let lineSpacing = paraStyle.lineSpacing
        let lineHeightMultiple = max(paraStyle.lineHeightMultiple, 1)
        let lineHeightMultipleOffset = (rect.size.height - rect.size.height/lineHeightMultiple)
        listMarkerImage.draw(at: markerRect.offsetBy(dx: 0, dy: lineHeightMultipleOffset).origin)
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
        let leftInset = layoutManagerDelegate?.textContainerInset.left ?? 0
        let spacerRect = CGRect(origin: CGPoint(x: rect.minX + leftInset, y: rect.minY + topInset), size: CGSize(width: indent, height: rect.height))
        let scaleFactor = markerSize.height / spacerRect.height
        var markerSizeToUse = markerSize
        // Resize maintaining aspect ratio if bullet height is more than available line height
        if scaleFactor > 1 {
            markerSizeToUse = CGSize(width: markerSize.width/scaleFactor, height: markerSize.height/scaleFactor)
        }

        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSizeToUse.width, y: spacerRect.midY - markerSizeToUse.height/2), size: markerSizeToUse)
        return stringRect
    }

    private func rectForNumberedList(markerSize: CGSize, rect: CGRect, indent: CGFloat, yOffset: CGFloat) -> CGRect {
        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
        let leftInset = layoutManagerDelegate?.textContainerInset.left ?? 0
        let spacerRect = CGRect(origin: CGPoint(x: rect.minX + leftInset, y: rect.minY + topInset), size: CGSize(width: indent, height: rect.height))

        let scaleFactor = markerSize.height / spacerRect.height
        var markerSizeToUse = markerSize
        // Resize maintaining aspect ratio if bullet height is more than available line height
        if scaleFactor > 1 {
            markerSizeToUse = CGSize(width: markerSize.width/scaleFactor, height: markerSize.height/scaleFactor)
        }

        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSizeToUse.width, y: spacerRect.minY + yOffset), size: markerSizeToUse)

        return stringRect
    }

    private func rectForLineNumbers(markerSize: CGSize, rect: CGRect, width: CGFloat) -> CGRect {
        let topInset = layoutManagerDelegate?.textContainerInset.top ?? 0
        let spacerRect = CGRect(origin: CGPoint(x: 0, y: topInset), size: CGSize(width: width, height: rect.height))

        let scaleFactor = markerSize.height / spacerRect.height
        var markerSizeToUse = markerSize
        // Resize maintaining aspect ratio if bullet height is more than available line height
        if scaleFactor > 1 {
            markerSizeToUse = CGSize(width: markerSize.width/scaleFactor, height: markerSize.height/scaleFactor)
        }

        let trailingPadding: CGFloat = 2
        let yPos = topInset + rect.minY
        let stringRect = CGRect(origin: CGPoint(x: spacerRect.maxX - markerSizeToUse.width - trailingPadding, y: yPos), size: markerSizeToUse)

        //        debugRect(rect: spacerRect, color: .blue)
        //        debugRect(rect: stringRect, color: .red)

        return stringRect
    }

    override func drawsOutsideLineFragment(forGlyphAt glyphIndex: Int) -> Bool {
        true
    }

    var hasLineSpacing: Bool {
        var lineCount = 0
        guard let textStorage else { return false}
        enumerateLineFragments(forGlyphRange: textStorage.fullRange, using: { _, _, _, _, stop in
            lineCount += 1
            if lineCount > 1 {
                stop.pointee = true
            }
        })
        return lineCount > 1 || (lineCount > 0 && extraLineFragmentRect.height > 0)
    }

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = textStorage,
              let currentCGContext = UIGraphicsGetCurrentContext()
        else { return }
        currentCGContext.saveGState()

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.backgroundStyle, in: characterRange) { attr, bgStyleRange, _ in
            var rects = [CGRect]()
            if let backgroundStyle = attr as? BackgroundStyle {
                let bgStyleGlyphRange = self.glyphRange(forCharacterRange: bgStyleRange, actualCharacterRange: nil)
                enumerateLineFragments(forGlyphRange: bgStyleGlyphRange) { rect1, usedRect, textContainer, lineRange, _ in
                    let rangeIntersection = NSIntersectionRange(bgStyleGlyphRange, lineRange)
                    let paragraphStyle = textStorage.attribute(.paragraphStyle, at: rangeIntersection.location, effectiveRange: nil) as? NSParagraphStyle ?? self.defaultParagraphStyle
                    let font = textStorage.attribute(.font, at: rangeIntersection.location, effectiveRange: nil) as? UIFont ?? self.defaultFont
                    let lineHeightMultiple = max(paragraphStyle.lineHeightMultiple, 1)
                    var rect = self.boundingRect(forGlyphRange: rangeIntersection, in: textContainer)
                    let lineHeightMultipleOffset = (rect.size.height - rect.size.height/lineHeightMultiple)
                    let lineSpacing = paragraphStyle.lineSpacing
                    if backgroundStyle.widthMode == .matchText {
                        let content = textStorage.attributedSubstring(from: rangeIntersection)
                        let contentWidth = content.boundingRect(with: rect.size, options: [.usesDeviceMetrics, .usesFontLeading], context: nil).width
                            rect.size.width = contentWidth
                    }

                    switch backgroundStyle.heightMode {
                    case .matchTextExact:
                        let styledText = textStorage.attributedSubstring(from: bgStyleGlyphRange)
                        var textRect = styledText.boundingRect(with: rect.size, options: [.usesFontLeading, .usesDeviceMetrics], context: nil)
                        textRect.origin = rect.origin
                        textRect.size.width = rect.width

                        textRect.origin.y += abs(font.descender)

                        let delta = usedRect.height - (font.lineHeight + font.leading)
                        textRect.origin.y += delta
                        let hasLineSpacing = (usedRect.height - font.lineHeight) == paragraphStyle.lineSpacing
                        let isExtraLineHeight = ((usedRect.height - font.lineHeight) - font.leading) > 0.001

                        if hasLineSpacing || isExtraLineHeight {
                            textRect.origin.y -= (paragraphStyle.lineSpacing - font.leading)
                        }

                        rect = textRect
                    case .matchText:
                        let styledText = textStorage.attributedSubstring(from: bgStyleGlyphRange)
                        let textRect = styledText.boundingRect(with: rect.size, options: .usesFontLeading, context: nil)

                        rect.origin.y = usedRect.origin.y + (rect.size.height - textRect.height) + lineHeightMultipleOffset - lineSpacing
                        rect.size.height = textRect.height - lineHeightMultipleOffset
                    case .matchLine:
                        // Glyphs can take space outside of the line fragment, and we cannot draw outside of it.
                        // So it is best to restrict the height just to the line fragment.
                        rect.origin.y = usedRect.origin.y
                        rect.size.height = usedRect.height
                    }

//                    if lineRange.endLocation == textStorage.length, font.leading == 0 {
//                        rect.origin.y += abs(font.descender/2)
//                    }
                    rects.append(rect.offsetBy(dx: origin.x, dy: origin.y))
                }
                drawBackground(backgroundStyle: backgroundStyle, rects: rects, currentCGContext: currentCGContext)
            }
        }
        drawLineNumbers(textStorage: textStorage, currentCGContext: currentCGContext)
        currentCGContext.restoreGState()
    }

    private func drawLineNumbers(textStorage: NSTextStorage, currentCGContext: CGContext) {
        var lineNumber = 1
        guard layoutManagerDelegate?.isLineNumbersEnabled == true,
              let lineNumberFormatting = layoutManagerDelegate?.lineNumberFormatting else { return }

        let lineNumberWrappingMarker = layoutManagerDelegate?.lineNumberWrappingMarker
        enumerateLineFragments(forGlyphRange: textStorage.fullRange) { [weak self] rect, usedRect, _, range, _ in
            guard let self else { return }
            let paraRange = self.textStorage?.mutableString.paragraphRange(for: range).firstCharacterRange
            let lineNumberToDisplay = layoutManagerDelegate?.lineNumberString(for: lineNumber) ?? "\(lineNumber)"

            if range.location == paraRange?.location {
                self.drawLineNumber(lineNumber: lineNumberToDisplay, rect: rect.integral, lineNumberFormatting: lineNumberFormatting, currentCGContext: currentCGContext)
                lineNumber += 1
            } else if let lineNumberWrappingMarker {
                self.drawLineNumber(lineNumber: lineNumberWrappingMarker, rect: rect.integral, lineNumberFormatting: lineNumberFormatting, currentCGContext: currentCGContext)
            }
        }

        // Draw line number for additional new line with \n, if exists
        drawLineNumber(lineNumber: "\(lineNumber)", rect: extraLineFragmentRect.integral, lineNumberFormatting: lineNumberFormatting, currentCGContext: currentCGContext)
    }
    
    func drawLineNumber(lineNumber: String, rect: CGRect, lineNumberFormatting: LineNumberFormatting, currentCGContext: CGContext) {
        let gutterWidth = lineNumberFormatting.gutter.width
        let attributes = lineNumberAttributes(lineNumberFormatting: lineNumberFormatting)
        let text = NSAttributedString(string: "\(lineNumber)", attributes: attributes)
        let markerSize = text.boundingRect(with: .zero, options: [], context: nil).integral.size
        var markerRect = self.rectForLineNumbers(markerSize: markerSize, rect: rect, width: gutterWidth)
        let listMarkerImage = self.generateBitmap(string: text, rect: markerRect)
        listMarkerImage.draw(at: markerRect.origin)
    }

    private func lineNumberAttributes(lineNumberFormatting: LineNumberFormatting) -> [NSAttributedString.Key: Any] {
        let font = lineNumberFormatting.font
        let textColor = lineNumberFormatting.textColor
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .right

        return [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.paragraphStyle: paraStyle
        ]
    }

    private func drawBackground(backgroundStyle: BackgroundStyle, rects: [CGRect], currentCGContext: CGContext) {
        currentCGContext.saveGState()

        let rectCount = rects.count
        let rectArray = rects

        let color = backgroundStyle.color

        for i in 0..<rectCount {
            var previousRect = CGRect.zero
            var nextRect = CGRect.zero

            let currentRect = rectArray[i].insetIfRequired(by: backgroundStyle.insets)

            if currentRect.isEmpty {
                continue
            }

            let cornerRadius: CGFloat

            switch backgroundStyle.roundedCornerStyle {
            case let .absolute(value):
                cornerRadius = value
            case let .relative(percent):
                cornerRadius = currentRect.height * (percent/100.0)
            }

            if i > 0 {
                previousRect = rectArray[i - 1].insetIfRequired(by: backgroundStyle.insets)
            }

            if i < rectCount - 1 {
                nextRect = rectArray[i + 1].insetIfRequired(by: backgroundStyle.insets)
            }

            let corners: UIRectCorner
            if backgroundStyle.hasSquaredOffJoins {
                corners = calculateCornersForSquaredOffJoins(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)
            } else {
               corners = calculateCornersForBackground(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)
            }

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
            var lineLength: CGFloat = 0

            if backgroundStyle.heightMode != .matchTextExact,
                !previousRect.isEmpty, (currentRect.maxX - previousRect.minX) > cornerRadius {
                let yDiff = currentRect.minY - previousRect.maxY
                var overLapMinX = max(previousRect.minX, currentRect.minX) + lineWidth/2
                var overlapMaxX = min(previousRect.maxX, currentRect.maxX) - lineWidth/2
                lineLength = overlapMaxX - overLapMinX

                // Adjust overlap line length if the rounding on current and previous overlaps
                // accounting for relative rounding as it rounds at both top and bottom vs. fixed which rounds
                // only at top when in an overlap
                if (currentRect.maxX - previousRect.minX <= cornerRadius)
                    || (previousRect.minX - currentRect.maxX <= cornerRadius) && backgroundStyle.roundedCornerStyle.isRelative  {
                    overLapMinX += cornerRadius
                    overlapMaxX -= cornerRadius
                }

                overlappingLine.move(to: CGPoint(x: overLapMinX , y: previousRect.maxY + yDiff/2))
                overlappingLine.addLine(to: CGPoint(x: overlapMaxX, y: previousRect.maxY + yDiff/2))

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

            if !currentRect.isEmpty,
                let borderColor = backgroundStyle.border?.color {
                currentCGContext.setLineWidth(lineWidth)
                currentCGContext.setStrokeColor(borderColor.cgColor)
                currentCGContext.addPath(rectanglePath.cgPath)

                // always draw vertical joining lines
                currentCGContext.addPath(leftVerticalJoiningLine.cgPath)
                currentCGContext.addPath(rightVerticalJoiningLine.cgPath)

                currentCGContext.drawPath(using: .stroke)
            }

            // draw over the overlapping bounds of previous and next rect to hide shadow/borders
            // if the border color is defined and different from background
            // Also, account for rounding so that the overlap line does not eat into rounding lines
            if let borderColor = backgroundStyle.border?.color,
               lineLength > (cornerRadius * 2),
                color != borderColor {
                currentCGContext.setStrokeColor(color.cgColor)
                currentCGContext.addPath(overlappingLine.cgPath)
            }
            // account for the spread of shadow
            let blur = (backgroundStyle.shadow?.blur ?? 1) * 2
            let offsetHeight = abs(backgroundStyle.shadow?.offset.height ?? 1)
            currentCGContext.setLineWidth(lineWidth + (currentRect.minY - previousRect.maxY) + blur + offsetHeight + 1)
            currentCGContext.drawPath(using: .stroke)
        }
        currentCGContext.restoreGState()
    }

    private func calculateCornersForSquaredOffJoins(previousRect: CGRect, currentRect: CGRect, nextRect: CGRect, cornerRadius: CGFloat) -> UIRectCorner {
        var corners = UIRectCorner()

        let isFirst = previousRect.isEmpty  && !currentRect.isEmpty
        let isLast = nextRect.isEmpty && !currentRect.isEmpty

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

        if nextRect.isEmpty || nextRect.maxX <= currentRect.minX + cornerRadius {
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
        }

        if previousRect.isEmpty || (currentRect.maxX <= previousRect.minX + cornerRadius) {
            corners.formUnion(.topLeft)
            corners.formUnion(.topRight)
        }

        return corners
    }

    // Helper function to debug rectangles by drawing in context
    private func debugRect(rect: CGRect, color: UIColor) {
        let path = UIBezierPath(rect: rect).cgPath
        debugPath(path: path, color: color)
    }

    // Helper function to debug Bezier Path by drawing in context
    private func debugPath(path: CGPath, color: UIColor) {
        let currentCGContext = UIGraphicsGetCurrentContext()
        currentCGContext?.saveGState()

        currentCGContext?.setStrokeColor(color.cgColor)
        currentCGContext?.addPath(path)
        currentCGContext?.drawPath(using: .stroke)

        currentCGContext?.restoreGState()
    }
}

extension CGRect {
    func insetIfRequired(by insets: UIEdgeInsets) -> CGRect {
        return isEmpty ? self : inset(by: insets)
    }
}

extension UIImage {
    func resizeImage(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: size
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: size
            ))
        }

        return scaledImage
    }
}

extension CGFloat {
    func isBetween(_ first: CGFloat, _ second: CGFloat) -> Bool {
        return self > first && self < second
    }
}
