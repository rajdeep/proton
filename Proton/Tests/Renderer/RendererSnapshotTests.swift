//
//  RendererSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 14/1/20.
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
import SnapshotTesting
import XCTest

import Proton

class RendererSnapshotTests: XCTestCase {
    var recordMode = false

    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testBasicRendering() {
        let viewController = RendererTestViewController()
        let renderer = viewController.renderer
        renderer.addBorder()

        renderer.attributedText = NSAttributedString(string: "Test string in renderer")

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testScrolledRendering() {
        let viewController = RendererTestViewController()
        let renderer = viewController.renderer
        renderer.addBorder()

        renderer.attributedText = NSAttributedString(string: """
        Line 1   - abc
        Line 2   - def
        Line 3   - ghi
        Line 4   - jkl
        Line 5   - mno
        Line 6   - pqr
        Line 7   - stu
        Line 8   - vwx
        Line 9   - yza
        Line 10  - bcd
        """)

        viewController.render()

        let findCommand = FindTextCommand(text: "pqr")
        findCommand.execute(on: renderer)

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
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

        editor.replaceCharacters(in: .zero, with: "This text is in Editor ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        let renderer = editor.convertToRenderer()
        let viewController = RendererTestViewController(renderer: renderer)
        renderer.attributedText = editor.attributedText

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGetsRectsForGivenRangeSpanningAcrossMultipleLines() {
        let viewController = RendererTestViewController()
        let renderer = viewController.renderer
        renderer.attributedText = NSAttributedString(string: "This is some long string in the Renderer that wraps into the next line.")
        viewController.render(size: CGSize(width: 300, height: 130))
        let rects = renderer.rects(for: NSRange(location: 25, length: 10))
        for rect in rects {
            let view = UIView(frame: rect)
            view.backgroundColor = .clear
            view.addBorder(.red)
            renderer.addSubview(view)
        }
        viewController.render(size: CGSize(width: 300, height: 130))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
}
