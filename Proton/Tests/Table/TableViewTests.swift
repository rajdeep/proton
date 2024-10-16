//
//  TableViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 10/4/2024.
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

class TableViewTests: XCTestCase {

    var delegate: MockTableViewDelegate!
    var window: UIWindow!
    var viewController: EditorTestViewController!
    var editor: EditorView!

    var config = GridConfiguration(
        columnsConfiguration: [
            GridColumnConfiguration(width: .fixed(100)),
            GridColumnConfiguration(width: .fixed(100)),
        ],
        rowsConfiguration: [
            GridRowConfiguration(initialHeight: 50),
            GridRowConfiguration(initialHeight: 50),
            GridRowConfiguration(initialHeight: 50),
        ])

    override func setUp() {
        super.setUp()
        delegate = MockTableViewDelegate()
        viewController = EditorTestViewController()
        editor = viewController.editor
        window = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 800)))
        window.makeKeyAndVisible()
        window.rootViewController = viewController
    }

    func testResolvesContainerScrollView() throws {
        delegate.containerScrollView = nil

        let viewport = CGRect(x: 0, y: 100, width: 350, height: 200)
        delegate.viewport = viewport

        let attachment = AttachmentGenerator.makeTableViewAttachment(
            id: 1,
            numRows: 20,
            numColumns: 5,
            initialRowHeight: 100
        )
        let tableView = attachment.view

        tableView.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render()

        XCTAssertNil(delegate.containerScrollView)
        XCTAssertEqual(attachment.view.containerScrollView, editor.scrollView)
    }

    func testReusesTextFromPreRenderedCells() throws {
        delegate.containerScrollView = editor.scrollView

        var viewport = CGRect(x: 0, y: 100, width: 350, height: 200)
        delegate.viewport = viewport

        let attachment = AttachmentGenerator.makeTableViewAttachment(
            id: 1,
            numRows: 20,
            numColumns: 5,
            initialRowHeight: 100
        )
        let tableView = attachment.view

        let filter: ((TableCell) throws -> Bool) = { $0.attributedText?.length ?? 0 > 0}

        tableView.delegate = delegate

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 700))
        attachment.view.scrollViewDidScroll(editor.scrollView)
        XCTAssertEqual(tableView.cellsInViewport.count, 12)
        XCTAssertEqual("{[0],[0]} {[0],[1]} {[0],[2]} {[0],[3]} {[1],[0]} {[1],[1]} {[1],[2]} {[1],[3]} {[2],[0]} {[2],[1]} {[2],[2]} {[2],[3]}",
                       try cellIDString(from: tableView.cellsInViewport, filter: filter))

        viewport = CGRect(x: 0, y: 300, width: 350, height: 200)
        delegate.viewport = viewport
        attachment.view.scrollViewDidScroll(editor.scrollView)
        viewController.render(size: CGSize(width: 400, height: 700))

        XCTAssertEqual(tableView.cellsInViewport.count, 12)
        XCTAssertEqual(
            """
            {[2],[0]} {[2],[1]} {[2],[2]} {[2],[3]} {[3],[0]} {[3],[1]} {[3],[2]} {[3],[3]} {[4],[0]} {[4],[1]} {[4],[2]} {[4],[3]}
            """,
            try cellIDString(from: tableView.cellsInViewport, filter: filter))


        viewport = CGRect(x: 0, y: 100, width: 350, height: 200)
        delegate.viewport = viewport
        attachment.view.scrollViewDidScroll(editor.scrollView)
        viewController.render(size: CGSize(width: 400, height: 700))

        XCTAssertEqual(tableView.cellsInViewport.count, 12)
        XCTAssertEqual(
            """
            {[0],[0]} {[0],[1]} {[0],[2]} {[0],[3]} {[1],[0]} {[1],[1]} {[1],[2]} {[1],[3]} {[2],[0]} {[2],[1]} {[2],[2]} {[2],[3]}
            """,
            try cellIDString(from: tableView.cellsInViewport, filter: filter))
    }

    func testIsCellSelectionEnabled() {
        let attachment = AttachmentGenerator.makeTableViewAttachment(
            id: 1,
            numRows: 20,
            numColumns: 5,
            initialRowHeight: 100
        )
        let tableView = attachment.view.tableView
        XCTAssertFalse(tableView.gestureRecognizers?.contains{ $0.name == tableView.selectionGestureRecognizerName } ?? false)

        tableView.isCellSelectionEnabled = true
        XCTAssertTrue(tableView.gestureRecognizers?.contains{ $0.name == tableView.selectionGestureRecognizerName } ?? false)
    }

    func FIXME_testChangesBoundsOfCell() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 2

        let tableView = TableView(config: config)
        let delegate = MockTableViewDelegate()
        tableView.delegate = delegate
        tableView.tableView.willMove(toWindow: UIWindow())
        tableView.tableView.updateCellFrames()
        let focusedCell = tableView.cellAt(rowIndex: 2, columnIndex: 1)
        var affectedCells = [
            (focusedCell, CGRect(x: 100.0, y: 100.0, width: 100.0, height: 60.0)),
            (tableView.cellAt(rowIndex: 2, columnIndex: 0), CGRect(x: 0.0, y: 100.0, width: 100.0, height: 60.0))
        ]

        delegate.onDidChangeBounds = { grid, bounds, cell in
            if let affectedIndex = affectedCells.firstIndex(where: {c, _ in c == cell }) {
                let (expectedCell, expectedFrame) = affectedCells.remove(at: affectedIndex)
                XCTAssertEqual(grid, tableView)
                XCTAssertEqual(bounds, expectedFrame.insetBy(borderWidth: self.config.style.borderWidth))
                XCTAssertEqual(expectedCell, cell)
                print(cell.id)
                print(bounds)
                expectation.fulfill()
            }
        }
        XCTAssertEqual(focusedCell?.frame, CGRect(x: 100, y: 100, width: 100, height: 50).insetBy(borderWidth: config.style.borderWidth))
//        focusedCell?.editor.replaceCharacters(in: .zero, with: "This is a test string")
        tableView.render()

        waitForExpectations(timeout: 1.0)
    }

    private func cellIDString(from cells: [TableCell], filter: ((TableCell) throws -> Bool)) throws -> String {
        try cells.filter(filter)
            .reduce("") { "\($0) \($1.id)" }
            .trimmingCharacters(in: .whitespaces)
    }
}
