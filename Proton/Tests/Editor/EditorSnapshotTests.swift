//
//  EditorSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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

        let rect1 = editor.caretRect(for: line1Location.location)
        let view1 = UIView(frame: rect1)
        view1.backgroundColor = .clear
        view1.addBorder(.green)
        editor.addSubview(view1)

        let rect2 = editor.caretRect(for: line2Location.location)
        let view2 = UIView(frame: rect2)
        view2.backgroundColor = .clear
        view2.addBorder(.red)
        editor.addSubview(view2)

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
}
