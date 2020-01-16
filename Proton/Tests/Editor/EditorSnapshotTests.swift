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
        viewController.render(size: CGSize(width: 300, height:120))
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

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
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

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
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

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
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

        editor.replaceCharacters(in: .zero, with: "This text is in Editor")
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
}
