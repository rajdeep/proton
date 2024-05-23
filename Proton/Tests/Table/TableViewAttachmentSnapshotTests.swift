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
    var viewController: EditorTestViewController!
    var editor: EditorView!

    override func setUp() {
        super.setUp()
        delegate = MockTableViewDelegate()
        viewController = EditorTestViewController()
        editor = viewController.editor
        delegate.containerScrollView = editor.scrollView
    }

    func testRendersTableViewAttachment() {
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

        let attachment = makeTableViewAttachment(config: config)
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 180))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentWithContainerBackgroundColor() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fractional(100))
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        let attachment = makeTableViewAttachment(config: config)

        editor.backgroundColor = .lightGray
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 300, height: 225))

        let cell = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        cell?.editor?.attributedText = NSAttributedString(string: "Test\nNew line\nMore text")
        cell?.backgroundColor = .white

        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.backgroundColor = .darkGray
        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentWithConstrainedFixedWidth() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(40)),
                GridColumnConfiguration(width: .fixed(50, min: { .absolute(60) })),
                GridColumnConfiguration(width: .fixed(500, max: { .viewport(padding: 0) })),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let cell00 = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        let cell01 = attachment.view.cellAt(rowIndex: 0, columnIndex: 1)
        let cell02 = attachment.view.cellAt(rowIndex: 0, columnIndex: 2)

        let cellOverlapPixels: CGFloat = 1
        XCTAssertEqual((cell00?.frame.width ?? 0) - cellOverlapPixels, 40)
        XCTAssertEqual((cell01?.frame.width ?? 0) - cellOverlapPixels, 60)
        XCTAssertEqual((cell02?.frame.width ?? 0) - cellOverlapPixels, 350)
    }

    func testRendersTableViewAttachmentWithViewportConstraints() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .viewport(padding: 0)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
        let cell = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        let lineFragmentPadding = editor.lineFragmentPadding
        let cellOverlapPixels: CGFloat = 1
        XCTAssertEqual((cell?.frame.width ?? 0) - cellOverlapPixels, editor.frame.width - (lineFragmentPadding * 2))

        viewController.render(size: CGSize(width: 700, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersNestedTableViewAttachmentWithViewportConstraints() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .viewport(padding: 0)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let tableAttachment = makeTableViewAttachment(config: config)
        var panel = PanelView()
        panel.editor.forceApplyAttributedText = true
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let panelAttachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = panelAttachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "Text in panel\n")
        panel.editor.replaceCharacters(in: panel.editor.textEndRange, with: tableAttachment.string)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 240))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentWithFractionalWidth() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fractional(0.25)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 80),
                GridRowConfiguration(initialHeight: 120),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentWithFractionalWidthMin() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.15, min: { .absolute(30) })),
                GridColumnConfiguration(width: .fractional(0.15, min: { .absolute(45) })),
                GridColumnConfiguration(width: .fractional(0.15, min: { .absolute(60) })),
                GridColumnConfiguration(width: .fixed(20))
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 300, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let cell00 = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        let cell01 = attachment.view.cellAt(rowIndex: 0, columnIndex: 1)
        let cell02 = attachment.view.cellAt(rowIndex: 0, columnIndex: 2)

        let lineFragmentPadding = editor.lineFragmentPadding
        let initialCellWidth = (editor.frame.width - (lineFragmentPadding * 2)) * 0.15
        let cellOverlapPixels: CGFloat = 1
        XCTAssertEqual((cell00?.frame.width ?? 0) - cellOverlapPixels, initialCellWidth)
        XCTAssertEqual((cell01?.frame.width ?? 0) - cellOverlapPixels, 45)
        XCTAssertEqual((cell02?.frame.width ?? 0) - cellOverlapPixels, 60)
    }

    func testRendersTableViewAttachmentWithFractionalWidthMinViewport() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.15, min: { .absolute(30) })),
                GridColumnConfiguration(width: .fractional(0.15, min: { .viewport(padding: 10)})),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 300, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let cell00 = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        let cell01 = attachment.view.cellAt(rowIndex: 0, columnIndex: 1)

        let lineFragmentPadding = editor.lineFragmentPadding
        let initialCellWidth = (editor.frame.width - (lineFragmentPadding * 2)) * 0.15
        let cellOverlapPixels: CGFloat = 1
        XCTAssertEqual((cell00?.frame.width ?? 0) - cellOverlapPixels, initialCellWidth)
        XCTAssertEqual((cell01?.frame.width ?? 0) - cellOverlapPixels, editor.frame.width - 10 - (2 * editor.lineFragmentPadding))
    }

    func testRendersTableViewAttachmentWithFractionalWidthMaxViewport() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.15, min: { .absolute(30) })),
                GridColumnConfiguration(width: .fractional(2.0, max: { .viewport(padding: 10)})),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 300, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let cell00 = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        let cell01 = attachment.view.cellAt(rowIndex: 0, columnIndex: 1)

        let lineFragmentPadding = editor.lineFragmentPadding
        let initialCellWidth = (editor.frame.width - (lineFragmentPadding * 2)) * 0.15
        let cellOverlapPixels: CGFloat = 1
        XCTAssertEqual((cell00?.frame.width ?? 0) - cellOverlapPixels, initialCellWidth)
        XCTAssertEqual((cell01?.frame.width ?? 0) - cellOverlapPixels, editor.frame.width - 10 - (2 * editor.lineFragmentPadding))
    }

    func testRendersGridViewAttachmentWithFractionalWidthMax() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.30, max: { .absolute(50) })),
                GridColumnConfiguration(width: .fractional(0.30, max: { .absolute(75) })),
                GridColumnConfiguration(width: .fractional(0.30, max: { .absolute(100) })),
                GridColumnConfiguration(width: .fixed(40))
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 300, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let cell00 = attachment.view.cellAt(rowIndex: 0, columnIndex: 0)
        let cell01 = attachment.view.cellAt(rowIndex: 0, columnIndex: 1)
        let cell02 = attachment.view.cellAt(rowIndex: 0, columnIndex: 2)

        let cellOverlapPixels: CGFloat = 1
        XCTAssertEqual((cell00?.frame.width ?? 0) - cellOverlapPixels, 50)
        XCTAssertEqual((cell01?.frame.width ?? 0) - cellOverlapPixels, 75)
        XCTAssertEqual((cell02?.frame.width ?? 0) - cellOverlapPixels, 75)
    }

    func testUpdatesCellSizeBasedOnContent() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        attachment.view.cells[0].attributedText = NSAttributedString(string: "Test some long text in the first cell")

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FIX_EDITOR_testMaintainsRowHeightBasedOnContent() throws {
        recordMode = true
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00 = try XCTUnwrap(attachment.view.cells[0])
        let cell01 = try XCTUnwrap(attachment.view.cells[1])

        // Render text which expands the first row
        cell00.attributedText = NSAttributedString(string: "Test some long text in the cell")
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)


        // Render text which expands the first row with longer text in second cell
        cell01.editor?.attributedText = NSAttributedString(string: "Test little longer text in the second cell")
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Render text which shrinks the first row due to shorter text in second cell
        cell01.editor?.attributedText = NSAttributedString(string: "Short text")
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Resets to blank state
        cell00.editor?.attributedText = NSAttributedString(string: "")
        cell01.editor?.attributedText = NSAttributedString(string: "")
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentWithStyledRow() {
        let style = GridCellStyle(
            backgroundColor: .lightGray,
            textColor: .darkGray,
            font: UIFont.systemFont(ofSize: 14, weight: .bold))
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30), style: style),
                GridColumnConfiguration(width: .fractional(0.45)),
                GridColumnConfiguration(width: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.cells[0]
        let cell10Editor = attachment.view.cells[3]

        cell00Editor.attributedText = NSAttributedString(string: "1.")
        cell10Editor.attributedText = NSAttributedString(string: "2.")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FLAKY_testRendersTableViewAttachmentWithStyledColumn() {
        let style = GridCellStyle(
            backgroundColor: .red,
            textColor: .white,
            font: UIFont.systemFont(ofSize: 14, weight: .bold))

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40, style: style),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )

        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00 = attachment.view.cells[0]
        let cell01 = attachment.view.cells[1]
        let cell02 = attachment.view.cells[2]

        cell00.attributedText = NSAttributedString(string: "Col 1")
        cell01.attributedText = NSAttributedString(string: "Col 2")
        cell02.attributedText = NSAttributedString(string: "Col 3")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FLAKY_testRendersTableViewAttachmentWithMixedStyles() {
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
                GridColumnConfiguration(width: .fractional(0.33)),
                GridColumnConfiguration(width: .fractional(0.33), style: columnStyle),
                GridColumnConfiguration(width: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40, style: rowStyle),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )

        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after sgrid")

        let cell00 = attachment.view.cells[0]
        let cell01 = attachment.view.cells[1]
        let cell02 = attachment.view.cells[2]

        let cell10 = attachment.view.cells[3]
        let cell11 = attachment.view.cells[4]
        let cell12 = attachment.view.cells[5]

        cell00.attributedText = NSAttributedString(string: "Cell 1")
        cell01.attributedText = NSAttributedString(string: "Cell 2")
        cell02.attributedText = NSAttributedString(string: "Cell 3")

        cell10.attributedText = NSAttributedString(string: "Cell 4")
        cell11.attributedText = NSAttributedString(string: "Cell 5")
        cell12.attributedText = NSAttributedString(string: "Cell 6")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testScrollsCellToVisible() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(150)),
                GridColumnConfiguration(width: .fractional(0.50)),
                GridColumnConfiguration(width: .fractional(0.40)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell05 = attachment.view.cells[5]
        cell05.attributedText = NSAttributedString(string: "Last cell")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        attachment.view.scrollToCellAt(rowIndex: 1, columnIndex: 2, animated: false)
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func TODO_testScrollsCellOutsideViewportToVisible() {

    }

    func FIXME_testRendersTableViewAttachmentWithMergedRows() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        let tableView = attachment.view
        let cell01 = try XCTUnwrap(tableView.cellAt(rowIndex: 0, columnIndex: 1))
        let cell11 = try XCTUnwrap(tableView.cellAt(rowIndex: 1, columnIndex: 1))

        cell01.attributedText = NSAttributedString(string: "Test string 1")
        cell11.attributedText = NSAttributedString(string: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        tableView.merge(cells: [cell01, cell11])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FIXME_testRendersTableViewAttachmentWithMergedColumns() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        let tableView = attachment.view
        let cell11 = try XCTUnwrap(tableView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(tableView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.attributedText = NSAttributedString(string: "Test string 1")
        cell12.attributedText = NSAttributedString(string: "Test string 2")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        tableView.merge(cells: [cell11, cell12])
        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FIXME_testRendersTableViewAttachmentWithMixedMergedRowsAndColumns() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )
        let attachment = makeTableViewAttachment(config: config)

        let tableView = attachment.view
        let cell11 = try XCTUnwrap(tableView.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(tableView.cellAt(rowIndex: 1, columnIndex: 2))

        cell11.attributedText = NSAttributedString(string: "Test string 1")
        cell12.attributedText = NSAttributedString(string: "Test string 2")

        let cell21 = try XCTUnwrap(tableView.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(tableView.cellAt(rowIndex: 2, columnIndex: 2))

        cell21.attributedText = NSAttributedString(string: "Test string 3")
        cell22.attributedText = NSAttributedString(string: "Test string 4")

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        tableView.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FLAKY_testTableShadows() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fractional(0.30)),
                GridColumnConfiguration(width: .fractional(0.30)),
                GridColumnConfiguration(width: .fractional(0.30)),
                GridColumnConfiguration(width: .fractional(0.30)),
                GridColumnConfiguration(width: .fractional(0.30)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),

            ],
            style: GridStyle(borderColor: .orange, borderWidth: 0.5),
            boundsLimitShadowColors: GradientColors(primary: .red, secondary: .yellow)
        )
        let attachment = makeTableViewAttachment(config: config)
        let table = attachment.view

        editor.textColor = .orange
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 200))
        table.scrollToCellAt(rowIndex: 1, columnIndex: 4)

        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testTableCellLayoutCompletion() {
        delegate.onDidLayoutCell = { _, cell in
            if cell.columnSpan.first == 0,
               let row = cell.rowSpan.first {
                cell.attributedText = NSAttributedString(string: "\(row + 1).", attributes: [.foregroundColor: UIColor.red])
            }
        }

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fixed(50)),
                GridColumnConfiguration(width: .fractional(0.30)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ],
            ignoresOptimizedInit: true
        )

        let attachment = makeTableViewAttachment(config: config)
        let tableView = attachment.view
        tableView.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 200))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewFromCells() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(200)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        var cells = [TableCell]()
        for row in 0..<2 {
            for col in 0..<2 {
                let cell = TableCell(rowSpan: [row], columnSpan: [col], initialHeight: 20)
                cell.attributedText = NSAttributedString(string: "{\(row), \(col)}")
                cells.append(cell)
            }
        }

        let attachment = makeTableViewAttachment(config: config, cells: cells)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewWithMergedRowsFromCells() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        var cells = [TableCell]()
        // 1st Row
        for row in 0..<1 {
            for col in 0..<3 {
                let cell = TableCell(rowSpan: [row], columnSpan: [col])
                cell.attributedText = NSAttributedString(string: "{\(row), \(col)}")
                cells.append(cell)
            }
        }

        // 1st column of 2nd and 3rd row merged
        let cell = TableCell(rowSpan: [1, 2], columnSpan: [0], style: GridCellStyle(backgroundColor: .yellow))
        cell.attributedText = NSAttributedString(string: "{(1,2), 0}")
        cells.append(cell)

        // 2nd and 3rd Rows
        for row in 1...2 {
            for col in 1...2 {
                let cell = TableCell(rowSpan: [row], columnSpan: [col])
                cell.attributedText = NSAttributedString(string: "{\(row), \(col)}")
                cells.append(cell)
            }
        }

        let attachment = makeTableViewAttachment(config: config, cells: cells)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewWithMergedColumnsFromCells() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        var cells = [TableCell]()
        // 1st Row
        let firstRow = 0
        for col in 0..<3 {
            let cell = TableCell(rowSpan: [firstRow], columnSpan: [col])
            cell.attributedText = NSAttributedString(string: "{\(firstRow), \(col)}")
            cells.append(cell)
        }


        // 2nd row, first column
        let cell = TableCell(rowSpan: [1], columnSpan: [0])
        cell.attributedText = NSAttributedString(string: "{0, 0}")
        cells.append(cell)

        // 2nd and 3rd columns of 2nd row merged
        let mergedCell = TableCell(rowSpan: [1], columnSpan: [1, 2], style: GridCellStyle(backgroundColor: .yellow))
        mergedCell.attributedText = NSAttributedString(string: "{1, (1, 2)}")
        cells.append(mergedCell)

        let thirdRow = 2
        for col in 0..<3 {
            let cell = TableCell(rowSpan: [thirdRow], columnSpan: [col])
            cell.attributedText = NSAttributedString(string: "{\(thirdRow), \(col)}")
            cells.append(cell)
        }

        let attachment = makeTableViewAttachment(config: config, cells: cells)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewWithMixedMergedColumnsAndRowsFromCells() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(80)),
                GridColumnConfiguration(width: .fixed(80)),
                GridColumnConfiguration(width: .fixed(90)),
                GridColumnConfiguration(width: .fixed(80)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 40),
            ])

        var cells = [TableCell]()
        // 1st Row
        let firstRow = 0
        for col in 0..<4 {
            let cell = TableCell(rowSpan: [firstRow], columnSpan: [col])
            cell.attributedText = NSAttributedString(string: "{\(firstRow), \(col)}")
            cells.append(cell)
        }

        // 2nd row, 1st and 2nd column
        let mergedRowCell = TableCell(rowSpan: [1], columnSpan: [0, 1], style: GridCellStyle(backgroundColor: .yellow))
        mergedRowCell.attributedText = NSAttributedString(string: "{0, (0, 1)}")

        cells.append(mergedRowCell)

        let secondRow = 1
        for col in 2...3 {
            let cell = TableCell(rowSpan: [secondRow], columnSpan: [col])
            cell.attributedText = NSAttributedString(string: "{\(secondRow), \(col)}")
            cells.append(cell)
        }

        for row in 2...4 {
            for col in 0...3 {
                if [2,3].contains(row) && col == 2 { continue }
                let cell = TableCell(rowSpan: [row], columnSpan: [col])
                cell.attributedText = NSAttributedString(string: "{\(row), \(col)}")
                cells.append(cell)
            }
        }

        let mergedColumnCell = TableCell(rowSpan: [2, 3], columnSpan: [2], style: GridCellStyle(backgroundColor: .yellow))
        mergedColumnCell.attributedText = NSAttributedString(string: "{(2, 3), 2}")
        cells.append(mergedColumnCell)

        let attachment = makeTableViewAttachment(config: config, cells: cells)

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FIX_EDITOR_testRendersTableViewWithCollapsedRows() {
        let attachment = make3By3TableViewAttachment()

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        attachment.view.collapseRow(at: 1)

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        attachment.view.expandRow(at: 1)

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersTableViewAttachmentInViewport() {
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

        table.cells[1].editor?.attributedText = NSAttributedString(string: String(repeating: text, count: 3))
        table.cells[4].editor?.attributedText = NSAttributedString(string: String(repeating: text, count: 4))
        table.cells[5].editor?.attributedText = NSAttributedString(string: String(repeating: text, count: 5))

        XCTAssertEqual(attachment.view.containerAttachment, attachment)

        viewController.render(size: CGSize(width: 400, height: 250))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func FIXME_testRendersViewportChangesWithVaryingContentHeight() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        delegate.containerScrollView = editor.scrollView

        let containerSize = CGSize(width: 400, height: 400)

        let attachment = AttachmentGenerator.makeTableViewAttachment(id: 1, numRows: 100, numColumns: 10)
        let table = attachment.view
        attachment.view.delegate = delegate
        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let text = "Text in cell "

        viewController.render(size: containerSize)

        table.cellAt(rowIndex: 1, columnIndex: 0)?.editor?.attributedText = NSAttributedString(string: String(repeating: text, count: 6))
        table.cellAt(rowIndex: 3, columnIndex: 0)?.editor?.attributedText = NSAttributedString(string: String(repeating: text, count: 5))

        viewController.render(size: containerSize)
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.scrollView.contentOffset = CGPoint(x: 0, y: 600)

        viewController.render(size: containerSize)
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.scrollView.contentOffset = CGPoint(x: 0, y: 0)

        viewController.render(size: containerSize)
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowAtIndexInMiddle() throws {
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
        let table = attachment.view
        attachment.view.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        table.insertRow(at: 1, configuration: GridRowConfiguration(initialHeight: 60))

        viewController.render(size: CGSize(width: 400, height: 400))
        let newCell11 = try XCTUnwrap(table.cellAt(rowIndex: 1, columnIndex: 1))
        newCell11.editor?.attributedText = NSAttributedString(string: "New cell")

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowAtTop() throws {
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
        let table = attachment.view
        attachment.view.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        table.insertRow(at: 0, configuration: GridRowConfiguration(initialHeight: 60))

        viewController.render(size: CGSize(width: 400, height: 400))
        let newCell01 = try XCTUnwrap(table.cellAt(rowIndex: 0, columnIndex: 1))
        newCell01.editor?.attributedText = NSAttributedString(string: "New cell")

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsRowAtBottom() throws {
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
        let table = attachment.view
        attachment.view.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        table.insertRow(at: 2, configuration: GridRowConfiguration(initialHeight: 60))

        viewController.render(size: CGSize(width: 400, height: 400))
        let newCell21 = try XCTUnwrap(table.cellAt(rowIndex: 2, columnIndex: 1))
        newCell21.editor?.attributedText = NSAttributedString(string: "New cell")

        // Editor shows caret for some reason - needs further investigation
        table.cellAt(rowIndex: 2, columnIndex: 0)?.editor?.isSelectable = false

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnInMiddle() throws {
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
        let table = attachment.view
        attachment.view.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        table.insertColumn(at: 1, configuration: GridColumnConfiguration(width: .fixed(80)))

        viewController.render(size: CGSize(width: 400, height: 400))
        let newCell11 = try XCTUnwrap(table.cellAt(rowIndex: 1, columnIndex: 1))
        newCell11.editor?.attributedText = NSAttributedString(string: "New cell")

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnAtBeginning() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fractional(0.50)),
                GridColumnConfiguration(width: .fixed(50)),
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

        table.insertColumn(at: 0, configuration: GridColumnConfiguration(width: .fractional(0.25)))

        viewController.render(size: CGSize(width: 400, height: 400))
        let newCell00 = try XCTUnwrap(table.cellAt(rowIndex: 0, columnIndex: 0))
        newCell00.editor?.attributedText = NSAttributedString(string: "New cell")

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testInsertsColumnAtEnd() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(30)),
                GridColumnConfiguration(width: .fixed(60)),
                GridColumnConfiguration(width: .fixed(60)),
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

        table.insertColumn(at: 3, configuration: GridColumnConfiguration(width: .fixed(150)))

        viewController.render(size: CGSize(width: 400, height: 400))
        let newCell21 = try XCTUnwrap(table.cellAt(rowIndex: 1, columnIndex: 3))
        newCell21.editor?.attributedText = NSAttributedString(string: "New cell")

        // Editor shows caret for some reason - needs further investigation
        table.cellAt(rowIndex: 2, columnIndex: 0)?.editor?.isSelectable = false

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }


    private func makeTableViewAttachment(config: GridConfiguration, cells: [TableCell] = []) -> TableViewAttachment {
        let attachment: TableViewAttachment
        if cells.count > 0 {
            attachment = TableViewAttachment(config: config, cells: cells)
        } else {
            attachment = TableViewAttachment(config: config)
        }
        attachment.view.delegate = delegate
        return attachment
    }

    private func make3By3TableViewAttachment() -> TableViewAttachment {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(150)),
                GridColumnConfiguration(width: .fixed(150)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 20),
                GridRowConfiguration(initialHeight: 20),
                GridRowConfiguration(initialHeight: 20),
            ])

        var cells = [TableCell]()
        for row in 0...2 {
            for col in 0...2 {
                let cell = TableCell(rowSpan: [row], columnSpan: [col], initialHeight: 20)
                cell.attributedText = NSAttributedString(string: "{\(row), \(col)}")
                cells.append(cell)
            }
        }

        let attachment = TableViewAttachment(config: config, cells: cells)
        attachment.view.delegate = delegate
        return attachment
    }
}
