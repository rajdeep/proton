//
//  TableViewAttachmentSnapshotTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/4/2024.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
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

class TableViewAttachmentSnapshotTests: SnapshotTestCase {
    var delegate: MockTableViewDelegate!

    override func setUp() {
        super.setUp()
        delegate = MockTableViewDelegate()
    }

    // This test is failing on every alternate run after recording
    // Issue is likely because of precision of fractional widths calculations
    func X_testRendersTableViewAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        delegate.containerScrollView = editor.scrollView

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fractional(0.45)),
                GridColumnConfiguration(width: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        let attachment = TableViewAttachment(config: config)
        attachment.view.delegate = delegate
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 180))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentInViewport() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        delegate.containerScrollView = editor.scrollView

        var viewport = CGRect(x: 0, y: 100, width: 350, height: 200)
        delegate.viewport = viewport

        Utility.drawRect(rect: viewport, color: .red, in: editor)

        let attachment = AttachmentGenerator.makeTableViewAttachment(id: 1, numRows: 20, numColumns: 5)
        attachment.view.delegate = delegate
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 700))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        viewport = CGRect(x: 0, y: 300, width: 350, height: 200)
        delegate.viewport = viewport
        attachment.view.scrollViewDidScroll(editor.scrollView)

        Utility.drawRect(rect: viewport, color: .red, in: editor)
        viewController.render(size: CGSize(width: 400, height: 700))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentInViewportRotation() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        delegate.containerScrollView = editor.scrollView

        var viewport = CGRect(x: 0, y: 100, width: 350, height: 200)
        delegate.viewport = viewport

        Utility.drawRect(rect: viewport, color: .red, in: editor)

        let attachment = AttachmentGenerator.makeTableViewAttachment(id: 1, numRows: 20, numColumns: 10)
        attachment.view.delegate = delegate
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 700))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        viewport = CGRect(x: 0, y: 100, width: 650, height: 200)
        delegate.viewport = viewport

        Utility.drawRect(rect: viewport, color: .red, in: editor)
        viewController.render(size: CGSize(width: 700, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewWithVaryingContentHeight() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        delegate.containerScrollView = editor.scrollView

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fixed(150)),
                GridColumnConfiguration(width: .fixed(200)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        let attachment = TableViewAttachment(config: config)
        let table = attachment.view
        attachment.view.delegate = delegate
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let text = "Text in cell "

        viewController.render(size: CGSize(width: 400, height: 250))

        table.cells[1].attributedText = NSAttributedString(string: String(repeating: text, count: 3))
        table.cells[4].attributedText = NSAttributedString(string: String(repeating: text, count: 4))
        table.cells[5].attributedText = NSAttributedString(string: String(repeating: text, count: 5))

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 250))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
}
