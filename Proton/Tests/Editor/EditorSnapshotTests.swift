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
import FBSnapshotTestCase

@testable import Proton

class EditorSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()

        recordMode = false
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
        viewController.render(size: CGSize(width: 300, height: 120))
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
    }

    func testRendersFullWidthAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = UIFont.systemFont(ofSize: 12)

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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
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

        FBSnapshotVerifyView(viewController.view)

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

        FBSnapshotVerifyView(viewController.view)

        let currentLineText1 = editor.currentLine?.text.string
        // refer to snapshot for visible text - green marker
        let expectedText1 = "Line 1 text Line 1 text Line 1 text "
        XCTAssertEqual(currentLineText1, expectedText1)

        // Change selected location to move to line 2
        editor.selectedRange = line2Location
        let currentLineText2 = editor.currentLine?.text.string
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

        FBSnapshotVerifyView(viewController.view)

        let firstLine = try XCTUnwrap(editor.firstLine)
        let nextLine = try XCTUnwrap(editor.lineAfter(firstLine))
        let lastLine = try XCTUnwrap(editor.lastLine)
        let prevLine = try XCTUnwrap(editor.lineBefore(lastLine))

        let firstLineText = editor.firstLine?.text.string
        let expectedText1 = "Line 1 text Line 1 text Line 1 text "
        XCTAssertEqual(firstLineText, expectedText1)

        let lastLineText = editor.lastLine?.text.string
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
        FBSnapshotVerifyView(viewController.view)
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
        FBSnapshotVerifyView(viewController.view)
    }

    func testBackgroundStyle() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let text =
        """
        Line 1 text Line 1 text Line 1 text Line 2 text Line 2 text Line 2 text Line 3 text Line 3
        """

        let rangeToUpdate = NSRange(location: 30, length: 50)

        editor.appendCharacters(NSAttributedString(string: text))
        viewController.render()
        let backgroundStyle = BackgroundStyle(cornerRadius: 4, shadow: ShadowStyle(color: .gray, offset: CGSize(width: 2, height: 2), blur: 3))
        editor.addAttribute(.backgroundColor, value: UIColor.green, at: rangeToUpdate)
        editor.addAttributes([
            .backgroundColor: UIColor.cyan,
            .backgroundStyle: backgroundStyle
        ], at: rangeToUpdate)

        viewController.render()
        FBSnapshotVerifyView(viewController.view)
    }


    private func addCaretRect(at range: NSRange, in editor: EditorView, color: UIColor) {
        let rect = editor.caretRect(for: range.location)
        let view = UIView(frame: rect)
        view.backgroundColor = .clear
        view.addBorder(color)
        editor.addSubview(view)
    }
}
