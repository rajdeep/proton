//
//  GridViewAttachmentTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/4/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
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
    // Issue seems to be with z-index of the cells. Needs to be revisited
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

        let attachment = makeTableViewAttachment(id: 1, numRows: 20, numColumns: 5)
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

    private func makeTableViewAttachment(id: Int, numRows: Int, numColumns: Int) -> TableViewAttachment {
        let config = GridConfiguration(
            columnsConfiguration: [GridColumnConfiguration](repeating: GridColumnConfiguration(width: .fixed(100)),
            count: numColumns),
            rowsConfiguration: [GridRowConfiguration](repeating: GridRowConfiguration(initialHeight: 100),
            count: numRows)
        )

        var cells = [TableCell]()
        for row in 0..<numRows {
            for col in 0..<numColumns {
                let editorInit = {
                    let editor = EditorView(allowAutogrowing: false)
                    editor.attributedText = NSAttributedString(string: "Table \(id) {\(row), \(col)} Text in cell")
                    return editor
                }
                let cell = TableCell(
                    rowSpan: [row],
                    columnSpan: [col],
                    initialHeight: 20,
                    editorInitializer: editorInit
                )
                cells.append(cell)
            }
        }

        let attachment = TableViewAttachment(config: config, cells: cells)
        attachment.view.delegate = delegate
        return attachment
    }

}
