//
//  RendererSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import FBSnapshotTestCase
import XCTest

import Proton

class RendererSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testBasicRendering() {
        let viewController = RendererTestViewController()
        let renderer = viewController.renderer
        renderer.addBorder()

        renderer.attributedText = NSAttributedString(string: "Test string in renderer")

        viewController.render()
        FBSnapshotVerifyView(viewController.view)
    }

    func testRendersAttachmentFromEditor() {
        let editor = EditorView()
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

        let renderer = editor.convertToRenderer()
        let viewController = RendererTestViewController(renderer: renderer)
        renderer.attributedText = editor.attributedText

        viewController.render()
        FBSnapshotVerifyView(viewController.view)
    }
}
