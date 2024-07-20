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

class EditorSnapshotTests: SnapshotTestCase {
    let mockLineNumberProvider = MockLineNumberProvider()

    override func setUp() {
        super.setUp()
        mockLineNumberProvider.indexOffSet = 0
    }

    func testRendersPlaceholder() {
        let viewController = EditorTestViewController(height: 80)
        let editor = viewController.editor
        let font = UIFont(name: "Verdana", size: 17) ?? UIFont()
        let placeholderString = NSMutableAttributedString(string: "Placeholder text that is so long that it wraps into the next line", attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.lightGray
        ])

        placeholderString.addAttribute(.font, value: font.adding(trait: .traitBold), range: NSRange(location: 12, length: 4))

        editor.placeholderText = placeholderString
        editor.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        viewController.render(size: CGSize(width: 300, height: 120))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testUpdatesPlaceholderWithInsets() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.contentInset = .zero
        editor.textContainerInset = .zero
        let font = UIFont(name: "Verdana", size: 17) ?? UIFont()
        let placeholderString = NSMutableAttributedString(string: "Placeholder text", attributes: [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.lightGray
        ])

        editor.placeholderText = placeholderString
        viewController.render(size: CGSize(width: 300, height: 60))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersMatchContentAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = UIFont.systemFont(ofSize: 12)

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

        editor.font = UIFont.systemFont(ofSize: 12)

        var panel = PanelView()
        panel.editor.forceApplyAttributedText = true
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

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
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

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

        editor.font = UIFont.systemFont(ofSize: 12)

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

        editor.font = UIFont.systemFont(ofSize: 12)

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

        editor.font = UIFont.systemFont(ofSize: 12)

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

    func testRendersAttachmentWithTextContainerInset() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = UIFont.systemFont(ofSize: 12)
        editor.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        var panel = PanelView()
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In full-width attachment")

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersAsyncAttachments() {
        let ex = functionExpectation()
        ex.expectedFulfillmentCount = 11
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let text = NSMutableAttributedString(string: "Text before panels")

        let delegate = MockAsyncAttachmentRenderingDelegate()
        delegate.onDidRenderAttachment = { _, _ in
            editor.render()
            ex.fulfill()
        }
        editor.asyncAttachmentRenderingDelegate = delegate

        for i in 1...10 {
            var panel = PanelView()
            panel.editor.forceApplyAttributedText = true
            panel.backgroundColor = .cyan
            panel.layer.borderWidth = 1.0
            panel.layer.cornerRadius = 4.0
            panel.layer.borderColor = UIColor.black.cgColor

            let attachment = Attachment(panel, size: .fullWidth)
            panel.boundsObserver = attachment
            panel.attributedText = NSAttributedString(string: "Panel id: \(i): Some text in the panel")
            text.append(attachment.string)
        }
        text.append(NSMutableAttributedString(string: "Text after panels"))
        editor.attributedText = text

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            viewController.render(size: CGSize(width: 300, height: 720))
            assertSnapshot(matching: viewController.view, as: .image, record: self.recordMode)
            ex.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testDeletesAttachments() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        editor.font = UIFont.systemFont(ofSize: 12)

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
            let view = UIView(frame: rect)
            view.backgroundColor = .clear
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
            let view = UIView(frame: rect)
            view.backgroundColor = .clear
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
        let view = UIView(frame: rect)
        view.backgroundColor = .clear
        view.addBorder(.blue)
        editor.addSubview(view)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsCaretRectForPositionInEmptyEditor() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let rect = editor.caretRect(for: 10)
        let view = UIView(frame: rect)
        view.backgroundColor = .clear
        view.addBorder(.green)
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
        let view = UIView(frame: rect)
        view.backgroundColor = .clear
        view.addBorder(.red)
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
        let view = UIView(frame: rect)
        view.backgroundColor = .clear
        view.addBorder(.blue)
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
        panel.editor.forceApplyAttributedText = true
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

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
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font
        panel.editor.forceApplyAttributedText = true

        panel.attributedText = NSAttributedString(string: "In \nfull-width \nattachment")

        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.appendCharacters("Four")
        editor.layoutIfNeeded()

        editor.selectedRange = NSRange(location: 6, length: 1)
        addSelectionRects(at: editor.selectedTextRange!, in: editor, color: .blue)

        editor.selectedRange = NSRange(location: 1, length: 4)
        addSelectionRects(at: editor.selectedTextRange!, in: editor, color: .magenta)

        editor.selectedRange = NSRange(location: 12, length: 10)
        addSelectionRects(at: editor.selectedTextRange!, in: editor, color: .green)

        editor.clipsToBounds = true
        editor.selectedRange = .zero
        viewController.render(size: .init(width: 300, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
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

        let visibleText = editor.attributedText.attributedSubstring(from: visibleRange ?? .zero).string
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

        let styles: [(String, pointSize: CGFloat, UIFont.Weight, paragraphBefore: CGFloat, paragraphAfter: CGFloat)] = [
            ("Heading 1", 27, .medium, 50, 15),
            ("Heading 2", 23.5, .medium, 22, 15),
            ("Heading 3", 17, .semibold, 20, 16),
            ("Heading 4", 17, .semibold, 4, 15),
            ("Heading 5", 14, .semibold, 5, 15),
            ("Heading 6", 12, .semibold, 4, 15),
        ]
        let para = NSAttributedString(string: "para --\n", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
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
                .font: UIFont.systemFont(ofSize: style.pointSize, weight: style.2),
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
        editor.addAttribute(.backgroundColor, value: UIColor.green, at: line2Range)
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
        let backgroundStyle = BackgroundStyle(color: .green, roundedCornerStyle: .absolute(value: 3), shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 3))
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
                                              roundedCornerStyle: .absolute(value: 5),
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
                                              roundedCornerStyle: .absolute(value: 4),
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
        let backgroundStyle = BackgroundStyle(color: .cyan, roundedCornerStyle: .absolute(value: 4), shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 2))
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
        let backgroundStyle = BackgroundStyle(color: .white, roundedCornerStyle: .absolute(value: 0), border: BorderStyle(lineWidth: 1, color: .brown))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testSuccessiveSimilarBackgroundStyles() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text = "Some Text"


        let backgroundStyle1 = BackgroundStyle(color: .yellow,
                                              roundedCornerStyle: .relative(percent: 50),
                                              border: BorderStyle(lineWidth: 1, color: .red))

        let backgroundStyle2 = BackgroundStyle(color: .yellow,
                                              roundedCornerStyle: .relative(percent: 50),
                                              border: BorderStyle(lineWidth: 1, color: .red))

        let editorText = NSMutableAttributedString(string: text, attributes: [.backgroundStyle: backgroundStyle1])
        editorText.append(NSAttributedString(string: text, attributes: [.backgroundStyle: backgroundStyle2]))

        editor.attributedText = editorText
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithInsets() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor



        let backgroundStyle = BackgroundStyle(color: .green,
                                              roundedCornerStyle: .relative(percent: 50),
                                              shadow: ShadowStyle(color: .red, offset: CGSize(width: 1, height: 1), blur: 0),
                                              insets: UIEdgeInsets(top: 1, left: -1, bottom: 1, right: -1)
        )

        let text = NSMutableAttributedString(string: " Test String 1 ", attributes: [.backgroundStyle: backgroundStyle])
        text.append(NSAttributedString(string: "\n"))
        text.append(NSMutableAttributedString(string: " Test String 2 ", attributes: [.backgroundStyle: backgroundStyle]))

        editor.appendCharacters(text)
        viewController.render()

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithCapsuleStyle() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.paragraphStyle.lineHeightMultiple = 1.12
        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 19, length: 36)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan, roundedCornerStyle: .relative(percent: 50), heightMode: .matchText)
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithHeightMatchingText() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 Text\nLine 2 Text
        """

        let rangeToUpdate = NSRange(location: 5, length: 14)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan.withAlphaComponent(0.5),
                                              roundedCornerStyle: .relative(percent: 50),
                                              border: BorderStyle(lineWidth: 1, color: .yellow),
                                              hasSquaredOffJoins: true,
                                              heightMode: .matchText)
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 130, height: 100))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithTextContainerInsets() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let text =
        """
        Line 1 Text\nLine 2 Text
        """

        let rangeToUpdate = NSRange(location: 5, length: 14)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              roundedCornerStyle: .relative(percent: 50),
                                              hasSquaredOffJoins: true,
                                              heightMode: .matchText)
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 160, height: 100))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithOverlappingLineNoBorder() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 Text\nLine 2 Text
        """

        let rangeToUpdate = NSRange(location: 5, length: 14)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              roundedCornerStyle: .relative(percent: 50),
                                              hasSquaredOffJoins: true,
                                              heightMode: .matchText)
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 130, height: 100))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithOverlappingLine() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 Text\nLine 2 Text
        """

        let rangeToUpdate = NSRange(location: 5, length: 16)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              roundedCornerStyle: .relative(percent: 50),
                                              border: BorderStyle(lineWidth: 1, color: .black),
                                              hasSquaredOffJoins: true,
                                              heightMode: .matchText)
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 150, height: 100))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithOverlappingLineExactTextHeight() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 Text\nLine 2 Text
        """

        let rangeToUpdate = NSRange(location: 5, length: 16)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              roundedCornerStyle: .relative(percent: 50),
//                                              border: BorderStyle(lineWidth: 1, color: .black),
                                              hasSquaredOffJoins: true,
                                              heightMode: .matchTextExact)
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 150, height: 100))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithVariedFontSizes() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.paragraphStyle.lineSpacing = 5
        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 3 text Line 3 text Line 3 text Line 4
        """

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render(size: CGSize(width: 300, height: 175))
        let backgroundStyle = BackgroundStyle(color: .cyan, roundedCornerStyle: .relative(percent: 50), heightMode: .matchText)


        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: NSRange(location: 7, length: 7))

        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: NSRange(location: 36, length: 5))

        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: NSRange(location: 45, length: 5))


        editor.addAttributes([.font: UIFont.systemFont(ofSize: 24)], at: NSRange(location: 0, length: 5))
        editor.addAttributes([.font: UIFont.systemFont(ofSize: 24)], at: NSRange(location: 35, length: 8))

        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithContinuity() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 2 text Line 2 text
        """

        let rangeToUpdate = NSRange(location: 12, length: 18)

        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24)]
        editor.appendCharacters(NSAttributedString(string: text, attributes: attributes))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              roundedCornerStyle: .relative(percent: 25),
                                              shadow: ShadowStyle(color: .red, offset: CGSize(width: 1, height: 1), blur: 0),
                                              hasSquaredOffJoins: true)
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
                                              roundedCornerStyle: .absolute(value: 5),
                                              border: BorderStyle(lineWidth: 1, color: .blue),
                                              shadow: ShadowStyle(color: .red, offset: CGSize(width: 2, height: 2), blur: 1))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithParagraphAndLineSpacing() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.paragraphStyle.paragraphSpacing = 13
        editor.paragraphStyle.lineSpacing = 4
//        editor.font = UIFont.systemFont(ofSize: 30, weight: .medium)

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 20, length: 58)

        editor.appendCharacters(NSAttributedString(string: text))

        let textField = AutogrowingTextField()
        textField.backgroundColor = .cyan
        textField.addBorder()
        textField.font = editor.font
        textField.text = "in1"

        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        let attachment = Attachment(textField, size: .matchContent)
        attachment.offsetProvider = offsetProvider
        textField.boundsObserver = attachment

        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)


        let textField1 = AutogrowingTextField()
        textField1.backgroundColor = .cyan
        textField1.addBorder()
        textField1.font = editor.font
        textField1.text = "in2"

        let attachment1 = Attachment(textField1, size: .matchContent)
        attachment1.offsetProvider = offsetProvider
        textField1.boundsObserver = attachment1

        editor.insertAttachment(in: NSRange(location: 52, length: 0), attachment: attachment1)

        viewController.render(size: CGSize(width: 300, height: 350))
        let backgroundStyle = BackgroundStyle(color: .cyan,
                                              roundedCornerStyle: .absolute(value: 5),
                                              border: BorderStyle(lineWidth: 1, color: .blue),
                                              heightMode: .matchTextExact, insets: UIEdgeInsets(top: -5, left: -2, bottom: -5, right: -2))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 300, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithIncreasedFontSize() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.font = UIFont.preferredFont(forTextStyle: .title1)

        let text =
        """
        Line 1 text Line 1 text Line 1 text \nLine 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 20, length: 52)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render(size: CGSize(width: 450, height: 150))
        let backgroundStyle = BackgroundStyle(color: .green,
                                              roundedCornerStyle: .absolute(value: 3),
                                              border: BorderStyle(lineWidth: 1, color: .yellow),
                                              shadow: ShadowStyle(color: .red, offset: CGSize(width: 2, height: -2), blur: 3))
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render(size: CGSize(width: 450, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testBackgroundStyleWithWidthModeAsText() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text


        Line 2 text Line 2 text Line 2 text

        Line 3 text Line 3
        """

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(color: .red,
                                              roundedCornerStyle: .absolute(value: 6),
                                              border: BorderStyle(lineWidth: 1, color: .yellow),
                                              shadow: ShadowStyle(color: .blue, offset: CGSize(width: 2, height: 2), blur: 2),
                                              widthMode: .matchText,
                                              insets: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        )
        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: NSRange(location: 19, length: 36))

        editor.addAttributes([
            .backgroundStyle: backgroundStyle
        ], at: NSRange(location: 70, length: 10))

        viewController.render(size: CGSize(width: 300, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testWrappedBackgroundInNestedEditor() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(60)),
                GridColumnConfiguration(width: .fractional(0.30)),
                GridColumnConfiguration(width: .fractional(0.30)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 300, height: 225))

        let backgroundStyle = BackgroundStyle(color: .red,
                                              roundedCornerStyle: .absolute(value: 6),
                                              border: BorderStyle(lineWidth: 1, color: .yellow),
                                              shadow: ShadowStyle(color: .blue, offset: CGSize(width: 2, height: 2), blur: 2),
                                              widthMode: .matchTextExact)

        let cell01 = attachment.view.cellAt(rowIndex: 0, columnIndex: 1)
        cell01?.editor.attributedText = NSAttributedString(string: "testLongString ThatWrapsToMultiple Lines", attributes: [.backgroundStyle: backgroundStyle, .textBlock: 1])

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

    func testGetsRangeForRect() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let editorString = NSAttributedString(string:
        """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed aliquam enim nunc. Maecenas porta turpis quam,
        sed ultricies enim condimentum ut. Vestibulum convallis nunc semper purus pellentesque varius. Phasellus
        accumsan odio nec est imperdiet, at mattis dolor elementum.
        """)
        editor.replaceCharacters(in: .zero, with: editorString)
        viewController.render(size: CGSize(width: 300, height: 300))

        let firstRect = CGRect(origin: .zero, size: CGSize(width: 50, height: 20))
        let rangeInFirstLine = try XCTUnwrap(editor.rangeForRect(firstRect))

        // Add marker to show actual requested rect
        let view = UIView(frame: firstRect)
        view.frame.origin = CGPoint(x: 5, y: 8)
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.borderWidth = 1
        view.backgroundColor = .clear
        editor.addSubview(view)

        let textRangeInFirstLine = try XCTUnwrap(rangeInFirstLine.toTextRange(textInput: editor.richTextView))
        addSelectionRects(at: textRangeInFirstLine, in: editor, color: .blue)
        XCTAssertEqual(rangeInFirstLine, NSRange(location: 0, length: 28))

        let rangeInLastLine = try XCTUnwrap(editor.rangeForRect(
            CGRect(origin: CGPoint(x: 5, y: 230), size: CGSize(width: 300, height: 30)))
        )
        let textRangeInLastLine = try XCTUnwrap(rangeInLastLine.toTextRange(textInput: editor.richTextView))

        addSelectionRects(at: textRangeInLastLine, in: editor, color: .red)
        XCTAssertEqual(rangeInLastLine, NSRange(location: 262, length: 10))
        let invalidRange = editor.rangeForRect(
            CGRect(origin: CGPoint(x: 5, y: 350), size: CGSize(width: 300, height: 30)))
        XCTAssertNil(invalidRange)

        viewController.render(size: CGSize(width: 300, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: false)
    }

    func testLineNumbersBlank() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.isLineNumbersEnabled = true
        viewController.render(size: CGSize(width: 300, height: 75))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
    
    func testLineNumbersDefault() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.isLineNumbersEnabled = true
        let text = """
           Test line 1
           Test line 2
           """
        
        editor.appendCharacters(NSAttributedString(string: text))
        
        viewController.render(size: CGSize(width: 300, height: 125))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testLineNumbersWithLineSpacing() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.paragraphStyle.lineSpacing = 30

        editor.isLineNumbersEnabled = true
        let text = """
           Test line 1 Test line 1 Test line 1 Test line 1
           Test line 2 Test line 1 Test line 1 Test line 1
           Test line 3 Test line 1 Test line 1
           Test line 4
           """

        editor.appendCharacters(NSAttributedString(string: text))

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testLineNumbersWithParagraphSpacing() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.paragraphStyle.paragraphSpacing = 30
        editor.lineNumberProvider = mockLineNumberProvider
        editor.isLineNumbersEnabled = true
        let text = """
           Test line 1 Test line 1 Test line 1 Test line 1
           Test line 2 Test line 1 Test line 1 Test line 1
           Test line 3 Test line 1 Test line 1
           Test line 4
           """

        editor.appendCharacters(NSAttributedString(string: text))

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FIXME_testLongLineNumbers() {
        recordMode = true
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.lineNumberProvider = mockLineNumberProvider
        mockLineNumberProvider.indexOffSet = 888
        editor.isLineNumbersEnabled = true
        let text = """
           Test line 1 Test line 1 Test line 1 Test line 1
           Test line 2 Test line 1 Test line 1 Test line 1
           Test line 3 Test line 1 Test line 1
           Test line 4
           """

        editor.appendCharacters(NSAttributedString(string: text))

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testLineNumbersEnableDisable() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        
        let text = """
           Test line 1
           Test line 2
           """
        
        editor.appendCharacters(NSAttributedString(string: text))
        
        editor.isLineNumbersEnabled = false
        viewController.render(size: CGSize(width: 300, height: 125))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
        
        editor.isLineNumbersEnabled = true
        viewController.render(size: CGSize(width: 300, height: 125))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
        
        editor.isLineNumbersEnabled = false
        viewController.render(size: CGSize(width: 300, height: 125))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
    
    func testLineNumbersWithFormatting() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.isLineNumbersEnabled = true
        editor.lineNumberFormatting = LineNumberFormatting(
            textColor: .white,
            font: UIFont.italicSystemFont(ofSize: 17),
            gutter: Gutter(
                width: 20,
                backgroundColor: .black,
                lineColor: .red,
                lineWidth: 2
            ))
        
        let text = """
           Test line 1
           Test line 2
           """
        
        editor.appendCharacters(NSAttributedString(string: text))
        
        viewController.render(size: CGSize(width: 300, height: 125))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
    
    
    func testLineNumbersWithWrappedText() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.isLineNumbersEnabled = true
        let text = """
           Test line 1 Test line 1 Test line 1 Test line 1 Test line 1 Test line 1
           Test line 2 Test line 2
           Test line 3 Test line 3
           """
        
        editor.appendCharacters(NSAttributedString(string: text))
        
        viewController.render(size: CGSize(width: 300, height: 220))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
    
    func testCustomLineNumbersWithWrappedText() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.lineNumberProvider = mockLineNumberProvider
        editor.isLineNumbersEnabled = true
        let text = """
           Test line 1 Test line 1 Test line 1 Test line 1 Test line 1 Test line 1
           Test line 2 Test line 2
           Test line 3 Test line 3
           """
        
        editor.appendCharacters(NSAttributedString(string: text))
        
        viewController.render(size: CGSize(width: 300, height: 220))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testSelectOnTap() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = UIFont.systemFont(ofSize: 12)

        var panel = PanelView()
        panel.editor.forceApplyAttributedText = true
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In full-width attachment")

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        let touch = UITouch()
        attachment.selectOnTap = true
        attachment.selectionStyle.alpha = 0.7
        attachment.selectionStyle.cornerRadius = 5
        (attachment.contentView?.superview as? AttachmentContentView)?.onContentViewTapped()

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testSelectOnTapInNonEditableEditor() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = UIFont.systemFont(ofSize: 12)

        var panel = PanelView()
        panel.editor.forceApplyAttributedText = true
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In full-width attachment")

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        editor.isEditable = false
        attachment.selectOnTap = true
        (attachment.contentView?.superview as? AttachmentContentView)?.onContentViewTapped()

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInvisibleCharacters() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text = NSMutableAttributedString(string: "Test text.")
        text.append(NSAttributedString(string: " Invisible text.", attributes: [
            .foregroundColor: UIColor.red,
            .invisible: 1
        ]))
        text.append(NSAttributedString(string: " After invisible characters"))

        editor.attributedText = text

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.showsInvisibleCharacters = true
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.showsInvisibleCharacters = false
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    private func addCaretRect(at range: NSRange, in editor: EditorView, color: UIColor) {
        let rect = editor.caretRect(for: range.location)
        let view = UIView(frame: rect)
        view.backgroundColor = .clear
        view.addBorder(color)
        editor.addSubview(view)
    }
}

extension XCTestCase {
    func addSelectionRects(at textRange: UITextRange, in editor: EditorView, color: UIColor) {
        editor.richTextView.selectionRects(for: textRange).forEach { selectionRect in
            let view = UIView(frame: editor.convert(selectionRect.rect, from: editor.richTextView))
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
}
