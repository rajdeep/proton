//
//  EditorSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
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
import XCTest
import SnapshotTesting

@testable import Proton

class EditorSnapshotTests: XCTestCase {
    var recordMode = false

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testRendersPlaceholder() {
        let viewController = EditorTestViewController(height: 80)
        let editor = viewController.editor
        let font = PlatformFont(name: "Verdana", size: 17) ?? PlatformFont()
        let placeholderString = NSMutableAttributedString(string: "Placeholder text that is so long that it wraps into the next line", attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: PlatformColor.lightGray
        ])

        placeholderString.addAttribute(.font, value: font.adding(trait: .traitBold), range: NSRange(location: 12, length: 4))

        editor.placeholderText = placeholderString
        viewController.render(size: CGSize(width: 300, height: 120))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersMatchContentAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = PlatformFont.systemFont(ofSize: 12)

        let textField = AutogrowingTextField()
        textField.backgroundColor = .cyan
        textField.addBorder()
        textField.font = editor.font
        textField.text = "in attachment"

        let attachment = Attachment(textField, size: .matchContent)
        textField.boundsObserver = attachment
        attachment.offsetProvider = offsetProvider

        editor.replaceCharacters(in: .zero, with: "This text is in Editor ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersFullWidthAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = PlatformFont.systemFont(ofSize: 12)

        var panel = PanelView()
        panel.setBackgroundColor(PlatformColor.cyan)
        panel.caLayer.borderWidth = 1.0
        panel.caLayer.cornerRadius = 4.0
        panel.caLayer.borderColor = PlatformColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In full-width attachment")

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersFullWidthAttachmentWithParaIndent() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.paragraphStyle.firstLineHeadIndent = 20
        editor.paragraphStyle.headIndent = 20

        var panel = PanelView()
        panel.setBackgroundColor(PlatformColor.cyan)
        panel.caLayer.borderWidth = 1.0
        panel.caLayer.cornerRadius = 4.0
        panel.caLayer.borderColor = PlatformColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In full-width attachment")

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersFixedWidthAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = PlatformFont.systemFont(ofSize: 12)

        let textField = AutogrowingTextField()
        textField.backgroundColor = .cyan
        textField.addBorder()
        textField.font = editor.font
        textField.text = "in fixed width attachment"

        let attachment = Attachment(textField, size: .fixed(width: 120))
        textField.boundsObserver = attachment
        attachment.offsetProvider = offsetProvider

        editor.replaceCharacters(in: .zero, with: "This text is in Editor ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersWidthRangeAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -1)

        editor.font = PlatformFont.systemFont(ofSize: 12)

        let inlineEditor = InlineEditorView()
        inlineEditor.textContainerInset = .zero
        inlineEditor.backgroundColor = .cyan
        inlineEditor.addBorder()

        let attachment = Attachment(inlineEditor, size: .range(minWidth: 50, maxWidth: 100))
        inlineEditor.boundsObserver = attachment
        inlineEditor.font = editor.font
        inlineEditor.replaceCharacters(in: .zero, with: "In width range text attachment")
        attachment.offsetProvider = offsetProvider

        editor.replaceCharacters(in: .zero, with: "This text is in Editor ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "and then some more text after the attachment")

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersPercentWidthAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = PlatformFont.systemFont(ofSize: 12)

        let textField = AutogrowingTextField()
        textField.backgroundColor = .cyan
        textField.addBorder()
        textField.font = editor.font
        textField.text = "in percent width attachment"

        let attachment = Attachment(textField, size: .percent(width: 50))
        textField.boundsObserver = attachment
        attachment.offsetProvider = offsetProvider

        editor.replaceCharacters(in: .zero, with: "This text is in Editor ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testDeletesAttachments() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        editor.font = PlatformFont.systemFont(ofSize: 12)

        let textField = AutogrowingTextField()
        textField.backgroundColor = .cyan
        textField.addBorder()
        textField.font = editor.font
        textField.text = "in attachment"

        let attachment = Attachment(textField, size: .matchContent)
        textField.boundsObserver = attachment

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        editor.attributedText.enumerateAttribute(.attachment, in: editor.attributedText.fullRange, options: .longestEffectiveRangeNotRequired) { value, range, _ in
            if value != nil {
                editor.replaceCharacters(in: range, with: "")
            }
        }

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsRectsForGivenRangeSpanningAcrossMultipleLines() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.attributedText = NSAttributedString(string: "This is some long string that wraps into the next line.")
        viewController.render()
        let rects = editor.rects(for: NSRange(location: 25, length: 10))
        for rect in rects {
            let view = PlatformView(frame: rect)
            view.setBackgroundColor(PlatformColor.clear)
            view.addBorder(.red)
            editor.addSubview(view)
        }
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsRectsForGivenRangeSpanningAcrossSingleLine() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.attributedText = NSAttributedString(string: "This is some long string that wraps into the next line.")
        viewController.render()
        let rects = editor.rects(for: NSRange(location: 10, length: 10))
        for rect in rects {
            let view = PlatformView(frame: rect)
            view.setBackgroundColor(PlatformColor.clear)
            view.addBorder(.red)
            editor.addSubview(view)
        }
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsCaretRectForValidPosition() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.attributedText = NSAttributedString(string: "This is some long string that wraps into the next line.")
        viewController.render()
        let rect = editor.caretRect(for: 10)
        let view = PlatformView(frame: rect)
        view.setBackgroundColor(PlatformColor.clear)
        view.addBorder(PlatformColor.blue)
        editor.addSubview(view)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsCaretRectForPositionInEmptyEditor() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let rect = editor.caretRect(for: 10)
        let view = PlatformView(frame: rect)
        view.setBackgroundColor(PlatformColor.clear)
        view.addBorder(PlatformColor.green)
        editor.addSubview(view)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsCaretRectForPositionOutsideBounds() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.attributedText = NSAttributedString(string: "some text")
        viewController.render()
        let rect = editor.caretRect(for: 20)
        let view = PlatformView(frame: rect)
        view.setBackgroundColor(PlatformColor.clear)
        view.addBorder(PlatformColor.red)
        editor.addSubview(view)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsCaretRectForValidPositionWithScrollableContent() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.attributedText = NSAttributedString(string:
            """
            This is some long string that wraps into the next line.
            This is some long string that wraps into the next line.
            This is some long string that wraps into the next line.
            This is some long string that wraps into the next line.
            """
        )

        viewController.render()
        editor.scrollRangeToVisible(NSRange(location: 150, length: 1))

        let rect = editor.caretRect(for: 150)
        let view = PlatformView(frame: rect)
        view.setBackgroundColor(PlatformColor.clear)
        view.addBorder(PlatformColor.blue)
        editor.addSubview(view)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testCursorCaretRect() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        
        editor.paragraphStyle.paragraphSpacingBefore = 16
        editor.paragraphStyle.paragraphSpacing = 8
        editor.attributedText = NSAttributedString(string: "One\nTwo\nThree")

        var panel = PanelView()
        panel.setBackgroundColor(PlatformColor.cyan)
        panel.caLayer.borderWidth = 1.0
        panel.caLayer.cornerRadius = 4.0
        panel.caLayer.borderColor = PlatformColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In \nfull-width \nattachment")

        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        viewController.render(size: .init(width: 300, height: 300))

        [0, 4, 6, 9, 14, 15].forEach {
            addCaretRect(at: .init(location: $0, length: 0), in: editor, color: .magenta)
        }

        viewController.render(size: .init(width: 300, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testSelectionRects() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        
        editor.textContainerInset = .init(top: 8, left: 4, bottom: 2, right: 6)
        editor.paragraphStyle.paragraphSpacingBefore = 16
        editor.paragraphStyle.paragraphSpacing = 8
        editor.attributedText = NSAttributedString(string: "One\nTwo\nThree")

        var panel = PanelView()
        panel.setBackgroundColor(PlatformColor.cyan)
        panel.caLayer.borderWidth = 1.0
        panel.caLayer.cornerRadius = 4.0
        panel.caLayer.borderColor = PlatformColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In \nfull-width \nattachment")

        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.appendCharacters("Four")
        editor.layoutIfNeeded()

        #if os(iOS)
        editor.selectedRange = NSRange(location: 6, length: 1)
        addSelectionRects(at: editor.selectedTextRange!, in: editor, color: PlatformColor.blue)

        editor.selectedRange = NSRange(location: 1, length: 4)
        addSelectionRects(at: editor.selectedTextRange!, in: editor, color: PlatformColor.magenta)

        editor.selectedRange = NSRange(location: 12, length: 10)
        addSelectionRects(at: editor.selectedTextRange!, in: editor, color: PlatformColor.green)
        
        editor.clipsToBounds = true
        viewController.render(size: .init(width: 300, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
        
        #else
        fatalError()
        #endif
    }
    
    func testGetsVisibleContentRange() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
            """
            Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of "de Finibus Bonorum et Malorum" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, "Lorem ipsum dolor sit amet..", comes from a line in section 1.10.32.
            """
        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        editor.scrollRangeToVisible(NSRange(location: 360, length: 1))

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let visibleRange = editor.visibleRange
        // refer to snapshot for visible text
        let expectedText = "consectetur, from a Lorem Ipsum passage, and going through the cites of the word in "
        let visibleText = editor.attributedText.attributedSubstring(from: visibleRange).string
        XCTAssertEqual(visibleText, expectedText)
    }

    func testGetsCurrentLineRange() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text
        """

        let line1Location = NSRange(location: 10, length: 1)
        let line2Location = NSRange(location: 40, length: 1)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        editor.selectedRange = line1Location

        addCaretRect(at: line1Location, in: editor, color: .green)
        addCaretRect(at: line2Location, in: editor, color: .red)

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let currentLineText1 = editor.currentLayoutLine?.text.string
        // refer to snapshot for visible text - green marker
        let expectedText1 = "Line 1 text Line 1 text Line 1 text "
        XCTAssertEqual(currentLineText1, expectedText1)

        // Change selected location to move to line 2
        editor.selectedRange = line2Location
        let currentLineText2 = editor.currentLayoutLine?.text.string
        // refer to snapshot for visible text - red marker
        let expectedText2 = "Line 2 text Line 2 text"
        XCTAssertEqual(currentLineText2, expectedText2)
    }

    func testLineRanges() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let line1Location = NSRange(location: 10, length: 1)
        let line2Location = NSRange(location: 40, length: 1)
        let line3Location = NSRange(location: 80, length: 1)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        editor.selectedRange = line1Location

        addCaretRect(at: line1Location, in: editor, color: .green)
        addCaretRect(at: line2Location, in: editor, color: .red)
        addCaretRect(at: line3Location, in: editor, color: .blue)

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let firstLine = try XCTUnwrap(editor.firstLayoutLine)
        let nextLine = try XCTUnwrap(editor.layoutLineAfter(firstLine))
        let lastLine = try XCTUnwrap(editor.lastLayoutLine)
        let prevLine = try XCTUnwrap(editor.layoutLineBefore(lastLine))

        let firstLineText = editor.firstLayoutLine?.text.string
        let expectedText1 = "Line 1 text Line 1 text Line 1 text "
        XCTAssertEqual(firstLineText, expectedText1)

        let lastLineText = editor.lastLayoutLine?.text.string
        let expectedText2 = "Line 3 text Line 3"
        XCTAssertEqual(lastLineText, expectedText2)

        XCTAssertEqual(nextLine.text.string, prevLine.text.string)

    }

    func testParagraphStyling() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let styles: [(String, pointSize: CGFloat, PlatformFont.Weight, paragraphBefore: CGFloat, paragraphAfter: CGFloat)] = [
            ("Heading 1", 27, .medium, 50, 15),
            ("Heading 2", 23.5, .medium, 22, 15),
            ("Heading 3", 17, .semibold, 20, 16),
            ("Heading 4", 17, .semibold, 4, 15),
            ("Heading 5", 14, .semibold, 5, 15),
            ("Heading 6", 12, .semibold, 4, 15),
        ]
        let para = NSAttributedString(string: "para --\n", attributes: [
            .font: PlatformFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: { () -> NSMutableParagraphStyle in
                let s = NSMutableParagraphStyle()
                s.paragraphSpacing = 20
                return s
            }(),
        ])
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "para --\n"))
        for style in styles {
            let pstyle = NSMutableParagraphStyle()
            pstyle.paragraphSpacingBefore = style.paragraphBefore
            pstyle.paragraphSpacing = style.paragraphAfter
            pstyle.headIndent = 60
            pstyle.tabStops = [
                NSTextTab(textAlignment: .natural, location: 30, options: [:]),
                NSTextTab(textAlignment: .natural, location: 60, options: [:]),
            ]
            text.append(NSAttributedString(string: "\(style.0)\n", attributes: [
                .font: PlatformFont.systemFont(ofSize: style.pointSize, weight: style.2),
                .paragraphStyle: pstyle,
            ]))
            text.append(para)
        }

        editor.attributedText = text
        viewController.render(size: CGSize(width: 300, height: 680))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testDefaultBackground() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let line2Range = NSRange(location: 36, length: 36)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        editor.addAttribute(.backgroundColor, value: PlatformColor.green, at: line2Range)
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleThreeLines() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 30, length: 49)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .green, cornerRadius: 3, shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 3))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleTwoLinesOverlap() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 20, length: 52)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              cornerRadius: 5,
                                              border: BorderStyle(lineWidth: 2, color: .red),
                                              shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 3))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleTwoLinesNoOverlap() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 19, length: 35)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              cornerRadius: 4,
                                              border: BorderStyle(lineWidth: 1, color: .blue),
                                              shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 2))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleTwoLinesMinorOverlap() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 19, length: 36)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan, cornerRadius: 4, shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 2))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithBorders() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 19, length: 36)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .white, cornerRadius: 0, border: BorderStyle(lineWidth: 1, color: .brown))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithIncreasedParagraphSpacing() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.paragraphStyle.paragraphSpacing = 20

        let text =
        """
        Line 1 text Line 1 text Line 1 text \nLine 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 20, length: 52)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render(size: CGSize(width: 300, height: 150))
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              cornerRadius: 5,
                                              border: BorderStyle(lineWidth: 1, color: .blue),
                                              shadow: ShadowStyle(color: .red, offset: CGSize(width: 2, height: 2), blur: 1))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithIncreasedFontSize() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.font = PlatformFont.preferredFont(forTextStyle: .title1)

        let text =
        """
        Line 1 text Line 1 text Line 1 text \nLine 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 20, length: 52)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render(size: CGSize(width: 450, height: 150))
        let backgroundStyle = BackgroundStyle(color: .green,
                                              cornerRadius: 3,
                                              border: BorderStyle(lineWidth: 1, color: .yellow),
                                              shadow: ShadowStyle(color: .red, offset: CGSize(width: 2, height: -2), blur: 3))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 450, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testEditorWithArabicText() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let text = "حية طيبة"
    
        editor.appendCharacters(NSAttributedString(string: text))

        viewController.render(size: CGSize(width: 450, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    private func addCaretRect(at range: NSRange, in editor: EditorView, color: PlatformColor) {
        let rect = editor.caretRect(for: range.location)
        let view = PlatformView(frame: rect)
        view.setBackgroundColor(PlatformColor.clear)
        view.addBorder(color)
        editor.addSubview(view)
    }

    #if os(iOS)
    private func addSelectionRects(at textRange: UITextRange, in editor: EditorView, color: PlatformColor) {
        editor.richTextView.selectionRects(for: textRange).forEach { selectionRect in
            let view = PlatformView(frame: editor.convert(selectionRect.rect, from: editor.richTextView))
            if selectionRect.containsStart || selectionRect.containsEnd {
                view.frame.origin.x -= 1
                view.frame.size.width = 2
                view.backgroundColor = .clear
                view.addBorder(color)
            } else {
                view.backgroundColor = color.withAlphaComponent(0.3)
            }
            editor.addSubview(view)
        }
    }
    #else
    // TODO: Implement on macOS
    #endif
}
