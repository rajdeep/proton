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

class GridViewAttachmentSnapshotTests: SnapshotTestCase {
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
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

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
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 80),
                GridRowConfiguration(initialHeight: 120),
            ])
        let attachment = GridViewAttachment(config: config)

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
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        attachment.view.cells[0].editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test some long text in the first cell"))

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
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.cells[0].editor
        let cell01Editor = attachment.view.cells[1].editor

        // Render text which expands the first row
        cell00Editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test some long text in the cell"))
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
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.cells[0].editor
        let cell10Editor = attachment.view.cells[3].editor

        cell00Editor.replaceCharacters(in: .zero, with: "1.")
        cell10Editor.replaceCharacters(in: .zero, with: "2.")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithStyledColumn() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let style = GridCellStyle(
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
                GridRowConfiguration(initialHeight: 40, style: style),
                GridRowConfiguration(initialHeight: 40),
            ])

        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.cells[0].editor
        let cell01Editor = attachment.view.cells[1].editor
        let cell02Editor = attachment.view.cells[2].editor

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
            backgroundColor: .red,
            textColor: .white,
            font: UIFont.systemFont(ofSize: 14, weight: .bold),
            borderStyle: GridCellStyle.BorderStyle(color: .yellow, width: 1)
        )

        let columnStyle = GridCellStyle(
            backgroundColor: .blue,
            textColor: .white,
            font: UIFont.systemFont(ofSize: 14, weight: .bold),
            borderStyle: GridCellStyle.BorderStyle(color: .green, width: 1)
        )

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33), style: columnStyle),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40, style: rowStyle),
                GridRowConfiguration(initialHeight: 40),
            ])

        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after sgrid")

        let cell00Editor = attachment.view.cells[0].editor
        let cell01Editor = attachment.view.cells[1].editor
        let cell02Editor = attachment.view.cells[2].editor

        let cell10Editor = attachment.view.cells[3].editor
        let cell11Editor = attachment.view.cells[4].editor
        let cell12Editor = attachment.view.cells[5].editor

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
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell05Editor = attachment.view.cells[5].editor
        cell05Editor.replaceCharacters(in: .zero, with: "Last cell")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        attachment.view.scrollToCellAt(rowIndex: 1, columnIndex: 2, animated: false)
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithMergedRows() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell01 = try XCTUnwrap(gridView.cellAt(rowIndex: 0, columnIndex: 1))
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))

        cell01.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell11.editor.replaceCharacters(in: .zero, with: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.merge(cells: [cell01, cell11])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }


    func testRendersGridViewAttachmentWithMergedColumns() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.merge(cells: [cell11, cell12])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithMixedMergedRowsAndColumns() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        let cell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 2))

        cell21.editor.replaceCharacters(in: .zero, with: "Test string 3")
        cell22.editor.replaceCharacters(in: .zero, with: "Test string 4")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithSplitRowsAndColumns() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        let cell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 2))

        cell21.editor.replaceCharacters(in: .zero, with: "Test string 3")
        cell22.editor.replaceCharacters(in: .zero, with: "Test string 4")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        gridView.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])


        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.split(cell: cell11)
        let newCell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))
        newCell12.editor.replaceCharacters(in: .zero, with: "Newly added text")

        viewController.render(size: CGSize(width: 400, height: 500))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowAtIndexInMiddle() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertRow(at: 1, configuration: GridRowConfiguration(initialHeight: 60))

        let newCell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        newCell11.editor.replaceCharacters(in: .zero, with: "New cell")

        viewController.render(size: CGSize(width: 400, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnAtIndexInMiddle() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertColumn(at: 1, configuration: GridColumnConfiguration(dimension: .fractional(0.20)))

        let newCell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        newCell11.editor.replaceCharacters(in: .zero, with: "New cell")

        viewController.render(size: CGSize(width: 500, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowAtTop() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view
        gridView.insertRow(at: 0, configuration: GridRowConfiguration(initialHeight: 60))

        let newCell01 = try XCTUnwrap(gridView.cellAt(rowIndex: 0, columnIndex: 1))
        newCell01.editor.replaceCharacters(in: .zero, with: "New cell")

        viewController.render(size: CGSize(width: 400, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowAtBottom() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view
        gridView.insertRow(at: 2, configuration: GridRowConfiguration(initialHeight: 60))

        let newCell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))
        newCell21.editor.replaceCharacters(in: .zero, with: "New cell")

        viewController.render(size: CGSize(width: 400, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnAtBeginning() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view
        gridView.insertColumn(at: 0, configuration: GridColumnConfiguration(dimension: .fractional(0.20)))

        let newCell10 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 0))
        newCell10.editor.replaceCharacters(in: .zero, with: "New cell")

        viewController.render(size: CGSize(width: 500, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnAtEnd() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view
        gridView.insertColumn(at: 3, configuration: GridColumnConfiguration(dimension: .fractional(0.20)))

        let newCell13 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 3))
        newCell13.editor.replaceCharacters(in: .zero, with: "New cell")

        viewController.render(size: CGSize(width: 500, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowInMixedMergedCells() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ]
        )
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")

        let cell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 2))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        gridView.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertRow(at: 2, configuration: GridRowConfiguration(initialHeight: 30))
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnInMixedMergedCells() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        gridView.merge(cells: [cell11, cell12])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertColumn(at: 2, configuration: GridColumnConfiguration(dimension: .fixed(40)))
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testDeletesColumn() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view

        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "C1")
        cell12.editor.replaceCharacters(in: .zero, with: "C2")

        viewController.render(size: CGSize(width: 200, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)


        gridView.deleteColumn(at: 1)

        viewController.render(size: CGSize(width: 200, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testDeletesMergedColumn() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
                GridColumnConfiguration(dimension: .fractional(0.35)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view

        let cell10 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 0))
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell10.editor.replaceCharacters(in: .zero, with: "C0")
        cell11.editor.replaceCharacters(in: .zero, with: "C1")
        cell12.editor.replaceCharacters(in: .zero, with: "C2")

        gridView.merge(cells: [cell10, cell11])

        viewController.render(size: CGSize(width: 200, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)


        gridView.deleteColumn(at: 1)

        viewController.render(size: CGSize(width: 200, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testDeletesRow() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(50)),
                GridColumnConfiguration(dimension: .fixed(50)),
                GridColumnConfiguration(dimension: .fixed(50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view

        let cell00 = try XCTUnwrap(gridView.cellAt(rowIndex: 0, columnIndex: 0))
        let cell10 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 0))
        let cell20 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 0))

        cell00.editor.replaceCharacters(in: .zero, with: "R1")
        cell10.editor.replaceCharacters(in: .zero, with: "R2")
        cell20.editor.replaceCharacters(in: .zero, with: "R3")

        viewController.render(size: CGSize(width: 201, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.deleteRow(at: 1)

        viewController.render(size: CGSize(width: 201, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testDeletesMergedRow() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(50)),
                GridColumnConfiguration(dimension: .fixed(50)),
                GridColumnConfiguration(dimension: .fixed(50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let gridView = attachment.view

        let cell00 = try XCTUnwrap(gridView.cellAt(rowIndex: 0, columnIndex: 0))
        let cell10 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 0))
        let cell20 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 0))

        let cell01 = try XCTUnwrap(gridView.cellAt(rowIndex: 0, columnIndex: 1))
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))

        cell00.editor.replaceCharacters(in: .zero, with: "1")
        cell10.editor.replaceCharacters(in: .zero, with: "2")
        cell20.editor.replaceCharacters(in: .zero, with: "3")

        cell01.editor.replaceCharacters(in: .zero, with: "4")
        cell11.editor.replaceCharacters(in: .zero, with: "5")
        cell21.editor.replaceCharacters(in: .zero, with: "6")

        gridView.merge(cells: [cell00, cell10])
        viewController.render(size: CGSize(width: 201, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.deleteRow(at: 1)

        viewController.render(size: CGSize(width: 201, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testMergesMultipleCells() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))
        let cell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "{1, 1} ")
        cell12.editor.replaceCharacters(in: .zero, with: "{1, 2} ")
        cell21.editor.replaceCharacters(in: .zero, with: "{2, 1} ")
        cell22.editor.replaceCharacters(in: .zero, with: "{2, 2} ")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        gridView.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertColumnInGridViewAttachmentWithMergedColumns() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell12.editor.replaceCharacters(in: .zero, with: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.merge(cells: [cell11, cell12])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertColumn(at: 1, configuration: GridColumnConfiguration(dimension: .fixed(50)))

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertRowInGridViewAttachmentWithMergedRows() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view
        let cell11 = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell21 = try XCTUnwrap(gridView.cellAt(rowIndex: 2, columnIndex: 1))

        cell11.editor.replaceCharacters(in: .zero, with: "Test string 1")
        cell21.editor.replaceCharacters(in: .zero, with: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.merge(cells: [cell11, cell21])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertRow(at: 1, configuration: GridRowConfiguration(initialHeight: 50))

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testAppliesStyleToNewRow() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertRow(at: 1, configuration: GridRowConfiguration(initialHeight: 50, style: GridCellStyle(backgroundColor: .red)))

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testAppliesStyleToNewColumn() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)

        let gridView = attachment.view

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.insertColumn(at: 1, configuration: GridColumnConfiguration(dimension: .fixed(50), style: GridCellStyle(backgroundColor: .red)))

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testFreezesRows() throws {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = GridViewAttachment(config: config)
        let gridView = attachment.view

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")


        for i in 1...8 {
            gridView.cellAt(rowIndex: i-1, columnIndex: 0)?.editor.attributedText = NSAttributedString(string: "\(i).")
        }

        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.freezeRows(upTo: 1)
        let style = GridCellStyle(backgroundColor: .gray, textColor: .white, borderStyle: GridCellStyle.BorderStyle(color: .white, width: 1))
        for i in 0...1 {
            gridView.applyStyle(style, toRow: i)
        }

        let cellFrame = try XCTUnwrap(gridView.cellAt(rowIndex: 6, columnIndex: 1)?.frame)
        editor.scrollRectToVisible(cellFrame, animated: false)
        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testFreezesColumns() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),

            ])
        let attachment = GridViewAttachment(config: config)
        let gridView = attachment.view

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")


        for i in 1...7 {
            gridView.cellAt(rowIndex: 0, columnIndex: i-1)?.editor.attributedText = NSAttributedString(string: "\(i).")
        }

        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        gridView.freezeColumns(upTo: 1)
        let style = GridCellStyle(backgroundColor: .gray, textColor: .white, borderStyle: GridCellStyle.BorderStyle(color: .white, width: 1))
        for i in 0...1 {
            gridView.applyStyle(style, toColumn: i)
        }

        gridView.scrollToCellAt(rowIndex: 1, columnIndex: 5)
        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGridShadows() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),

            ],
            style: GridStyle(borderColor: .orange, borderWidth: 0.5),
            boundsLimitShadowColors: GradientColors(primary: .red, secondary: .yellow)
        )
        let attachment = GridViewAttachment(config: config)
        let gridView = attachment.view

        editor.textColor = .orange
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 200))
        gridView.scrollToCellAt(rowIndex: 1, columnIndex: 4)

        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testGridCellLayoutCompletion() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let delegate = MockGridViewDelegate()
        delegate.onDidLayoutCell = { _, cell in
            if cell.columnSpan.first == 0,
               let row = cell.rowSpan.first {
                cell.editor.textColor = UIColor.red
                cell.editor.attributedText = NSAttributedString(string: "\(row + 1).")
            }
        }

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fixed(50)),
                GridColumnConfiguration(dimension: .fractional(0.30)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ]
        )
        let attachment = GridViewAttachment(config: config)
        let gridView = attachment.view
        gridView.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
}
