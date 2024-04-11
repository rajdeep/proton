//
//  GridViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 9/6/2022.
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

@testable import Proton

class GridViewTests: XCTestCase {
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

    func testFocusesCell() {
        let expectation = functionExpectation()
        let context = EditorViewContext.shared
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let rangeToSelect = NSRange(location: 2, length: 2)
        let focusedCell = gridView.cellAt(rowIndex: 2, columnIndex: 1)!

        delegate.onDidReceiveFocus = { grid, range, cell in
            XCTAssertEqual(grid, gridView)
            XCTAssertEqual(range, rangeToSelect)
            XCTAssertEqual(focusedCell, cell)
            expectation.fulfill()
        }
        focusedCell.editor.replaceCharacters(in: .zero, with: "This is a test string")
        focusedCell.editor.selectedRange = rangeToSelect
        context.richTextViewContext.textViewDidBeginEditing(focusedCell.editor.richTextView)

        waitForExpectations(timeout: 1.0)
    }

    func testResignsFocusFromCell() {
        let expectation = functionExpectation()
        let context = EditorViewContext.shared
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let rangeToSelect = NSRange(location: 2, length: 2)
        let focusedCell = gridView.cellAt(rowIndex: 2, columnIndex: 1)!

        delegate.onDidLoseFocus = { grid, range, cell in
            XCTAssertEqual(grid, gridView)
            XCTAssertEqual(range, rangeToSelect)
            XCTAssertEqual(focusedCell, cell)
            expectation.fulfill()
        }
        focusedCell.editor.replaceCharacters(in: .zero, with: "This is a test string")
        focusedCell.editor.selectedRange = rangeToSelect
        context.richTextViewContext.textViewDidBeginEditing(focusedCell.editor.richTextView)
        context.richTextViewContext.textViewDidEndEditing(focusedCell.editor.richTextView)

        waitForExpectations(timeout: 1.0)
    }

    func testChangesBoundsOfCell() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 2

        let gridView = GridView(config: config)
        gridView.frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 200))
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let focusedCell = gridView.cellAt(rowIndex: 2, columnIndex: 1)
        var affectedCells = [
            (focusedCell, CGRect(x: 100.0, y: 100.0, width: 100.0, height: 60.0)),
            (gridView.cellAt(rowIndex: 2, columnIndex: 0), CGRect(x: 0.0, y: 100.0, width: 100.0, height: 60.0))
        ]

        delegate.onDidChangeBounds = { grid, bounds, cell in
            if let affectedIndex = affectedCells.firstIndex(where: {c, _ in c == cell }) {
                let (expectedCell, expectedFrame) = affectedCells.remove(at: affectedIndex)
                XCTAssertEqual(grid, gridView)
                XCTAssertEqual(bounds, expectedFrame.insetBy(borderWidth: self.config.style.borderWidth))
                XCTAssertEqual(expectedCell, cell)
                print(cell.id)
                print(bounds)
                expectation.fulfill()
            }
        }
        XCTAssertEqual(focusedCell?.frame, CGRect(x: 100, y: 100, width: 100, height: 50).insetBy(borderWidth: config.style.borderWidth))
        focusedCell?.editor.replaceCharacters(in: .zero, with: "This is a test string")
        gridView.render()

        waitForExpectations(timeout: 1.0)
    }

    func testTapAtLocationInCell() {
        let expectation = functionExpectation()

        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let expectedCell = gridView.cellAt(rowIndex: 2, columnIndex: 1)
        let point = CGPoint(x: 40, y: 20)

        delegate.onDidTapAtLocation = { grid, location, range , cell in
            XCTAssertEqual(grid, gridView)
            XCTAssertEqual(location, point)
            XCTAssertEqual(range, NSRange(location: 4, length: 1))
            XCTAssertEqual(expectedCell, cell)
            expectation.fulfill()
        }
        expectedCell?.editor.replaceCharacters(in: .zero, with: "This is a test string")
        gridView.render()
        expectedCell?.editor.richTextView.didTap(at: CGPoint(x: 40, y: 20))

        waitForExpectations(timeout: 1.0)
    }

    func testChangeSelectionInCell() {
        let expectation = functionExpectation()

        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let expectedCell = gridView.cellAt(rowIndex: 2, columnIndex: 1)
        let rangeToSelect = NSRange(location: 4, length: 3)

        delegate.onDidChangeSelection = { grid, range, attributes, _, cell in
            XCTAssertEqual(grid, gridView)
            XCTAssertEqual(range, rangeToSelect)
            XCTAssertFalse(attributes.isEmpty)
            XCTAssertEqual(expectedCell, cell)

            expectation.fulfill()
        }
        expectedCell?.editor.replaceCharacters(in: .zero, with: "This is a test string")
        gridView.render()
        expectedCell?.editor.selectedRange = rangeToSelect

        waitForExpectations(timeout: 1.0)
    }

    func testGetsCellFromEditor() throws {
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let cellToQuery = try XCTUnwrap(gridView.cellAt(rowIndex: 1, columnIndex: 1))
        let editorToQuery = try XCTUnwrap(cellToQuery.editor)

        let cell = gridView.cellFor(editorToQuery)
        XCTAssertEqual(cell, cellToQuery)
    }

    func testUsesCustomEditorInit() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = config.numberOfColumns * config.numberOfRows

        let editorInit = {
            expectation.fulfill()
            return EditorView(frame: .zero)
        }

        let gridView = GridView(config: config, cellEditorInitializer: editorInit)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        waitForExpectations(timeout: 1.0)
    }

    func testNotifiesOfCellSelectionChanges() throws {
        let expectation = functionExpectation()
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        var cellsToSelect = gridView.cells.filter { $0.rowSpan.contains(0) }
        var column = 0
        expectation.expectedFulfillmentCount = cellsToSelect.count
        delegate.onDidSelectCells = { _, cells in
            if let lastCell = cells.last {
                XCTAssertTrue(cellsToSelect.contains(lastCell))
                XCTAssertEqual(lastCell.columnSpan.first, column)
                column += 1
                expectation.fulfill()
            }
        }
        gridView.selectCells(cellsToSelect)
        waitForExpectations(timeout: 1.0)
    }

    func testDeselectsCellAfterMerge() {
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let cells = gridView.cells.filter({ $0.rowSpan.first ?? 0 < 2 && $0.columnSpan.first ?? 0 < 2 })
        gridView.selectCells(cells)

        XCTAssertEqual(gridView.selectedCells.count, 4)
        gridView.merge(cells: cells)
        XCTAssertEqual(gridView.selectedCells.count, 0)
    }

    func testDeselectsCellAfterSplit() {
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        let cells = gridView.cells.filter({ $0.rowSpan.first ?? 0 < 2 && $0.columnSpan.first ?? 0 < 2 })
        gridView.selectCells(cells)

        XCTAssertEqual(gridView.selectedCells.count, 4)
        XCTAssertEqual(gridView.cells.count, 6)
        gridView.merge(cells: cells)
        XCTAssertEqual(gridView.cells.count, 3)
        gridView.selectCells([cells[0]])
        gridView.split(cell: cells[0])
        XCTAssertEqual(gridView.cells.count, 6)
        XCTAssertEqual(gridView.selectedCells.count, 0)
    }

    func testIgnoresNonSelectableCellsOnSelection() {
        let gridView = GridView(config: config)
        let delegate = MockGridViewDelegate()
        gridView.delegate = delegate
        gridView.gridView.willMove(toWindow: UIWindow())

        gridView.cells.filter({ $0.rowSpan.first ?? 0 < 2 && $0.columnSpan.first ?? 0 < 1 }).forEach {
            $0.isSelectable = false
        }
        gridView.selectCells(gridView.cells.filter({ $0.rowSpan.first ?? 0 < 2 && $0.columnSpan.first ?? 0 < 2 }))
        XCTAssertEqual(gridView.selectedCells.count, 2)
        XCTAssertEqual(gridView.selectedCells[0].id, "{[0],[1]}")
        XCTAssertEqual(gridView.selectedCells[1].id, "{[1],[1]}")
    }
}
