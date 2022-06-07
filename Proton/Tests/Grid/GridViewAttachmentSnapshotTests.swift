//
//  GridViewAttachmentTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
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

class GridViewAttachmentSnapshotTests: XCTestCase {
    var recordMode = false

    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testRendersGridViewAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithFractionalWidth() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 80, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 120, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testUpdatesCellSizeBasedOnContent() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        attachment.view.grid.cells[0].editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test long text in the first cell"))

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testMaintainsRowHeightBasedOnContent() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.grid.cells[0].editor
        let cell01Editor = attachment.view.grid.cells[1].editor

        // Render text which expands the first row
        cell00Editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test some text cell"))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)


        // Render text which expands the first row with longer text in second cell
        cell01Editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test longer text in the second cell"))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Render text which shrinks the first row due to shorter text in second cell
        cell01Editor.replaceCharacters(in: cell01Editor.attributedText.fullRange, with: NSAttributedString(string: "Short text"))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Resets to blank state
        cell00Editor.replaceCharacters(in: cell00Editor.attributedText.fullRange, with: NSAttributedString(string: ""))
        cell01Editor.replaceCharacters(in: cell01Editor.attributedText.fullRange, with: NSAttributedString(string: ""))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithStyledRow() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let style = GridCellStyle(
            borderColor: .blue,
            borderWidth: 1,
            cornerRadius: 3,
            backgroundColor: .lightGray,
            textColor: .darkGray,
            font: UIFont.systemFont(ofSize: 14, weight: .bold))
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30), style: style),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.grid.cells[0].editor
        let cell10Editor = attachment.view.grid.cells[3].editor

        cell00Editor.replaceCharacters(in: .zero, with: "1.")
        cell10Editor.replaceCharacters(in: .zero, with: "2.")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithStyledColumn() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let style = GridCellStyle(
            borderColor: .darkGray,
            borderWidth: 1,
            cornerRadius: 3,
            backgroundColor: .red,
            textColor: .white,
            font: UIFont.systemFont(ofSize: 14, weight: .bold))

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400, style: style),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])

        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.grid.cells[0].editor
        let cell01Editor = attachment.view.grid.cells[1].editor
        let cell02Editor = attachment.view.grid.cells[2].editor

        cell00Editor.replaceCharacters(in: .zero, with: "Col 1")
        cell01Editor.replaceCharacters(in: .zero, with: "Col 2")
        cell02Editor.replaceCharacters(in: .zero, with: "Col 3")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithMixedStyles() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let rowStyle = GridCellStyle(
            borderColor: .darkGray,
            borderWidth: 1,
            cornerRadius: 3,
            backgroundColor: .red,
            textColor: .white,
            font: UIFont.systemFont(ofSize: 14, weight: .bold))

        let columnStyle = GridCellStyle(
            borderColor: .red,
            borderWidth: 2,
            cornerRadius: 3,
            backgroundColor: .blue,
            textColor: .white,
            font: UIFont.systemFont(ofSize: 14, weight: .bold))

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33), style: columnStyle),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400, style: rowStyle),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])

        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.grid.cells[0].editor
        let cell01Editor = attachment.view.grid.cells[1].editor
        let cell02Editor = attachment.view.grid.cells[2].editor

        let cell10Editor = attachment.view.grid.cells[3].editor
        let cell11Editor = attachment.view.grid.cells[4].editor
        let cell12Editor = attachment.view.grid.cells[5].editor

        cell00Editor.replaceCharacters(in: .zero, with: "Cell 1")
        cell01Editor.replaceCharacters(in: .zero, with: "Cell 2")
        cell02Editor.replaceCharacters(in: .zero, with: "Cell 3")

        cell10Editor.replaceCharacters(in: .zero, with: "Cell 4")
        cell11Editor.replaceCharacters(in: .zero, with: "Cell 5")
        cell12Editor.replaceCharacters(in: .zero, with: "Cell 6")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testScrollsCellToVisible() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(150)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
                GridColumnConfiguration(dimension: .fractional(0.40)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 300, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell05Editor = attachment.view.grid.cells[5].editor
        cell05Editor.replaceCharacters(in: .zero, with: "Last cell")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: true)

        attachment.view.scrollToCellAt(rowIndex: 1, columnIndex: 2, animated: false)
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: true)
    }
}
