//
//  EditorCommandSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest
import FBSnapshotTestCase

@testable import Proton


class EditorCommandSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testExecutesCommandOnNestedEditors() {
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

        let context = EditorViewContext(name: "test_context")
        let commandExecutor = EditorCommandExecutor(context: context)

        editor.selectedRange = NSRange(location: 5, length: 4)
        context.richTextViewContext.textViewDidBeginEditing(editor.richTextView)
        commandExecutor.execute(BoldCommand())

        context.richTextViewContext.textViewDidEndEditing(editor.richTextView)

        panel.editor.richTextView.selectedRange = NSRange(location: 2, length: 11)
        context.richTextViewContext.textViewDidBeginEditing(panel.editor.richTextView)
        commandExecutor.execute(ItalicsCommand())

        viewController.render()

        FBSnapshotVerifyView(viewController.view)
    }
}
