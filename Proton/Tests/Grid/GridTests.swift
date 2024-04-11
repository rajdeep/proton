//
//  GridTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/6/2022.
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

class GridTests: XCTestCase {
    func testGeneratesGridCells() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let cells = grid.cells
        XCTAssertEqual(cells.count, 6)
        var counter = 0

        for i in 0..<3 {
            for j in 0..<2 {
                let cell = cells[counter]
                XCTAssertEqual(cell.rowSpan, [i])
                XCTAssertEqual(cell.columnSpan, [j])
                counter += 1
            }
        }
    }

    func testGetsFrameForCell() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let size = CGSize(width: 300, height: 150)
        let grid = Grid(config: config, cells: generateCells(config: config))
        grid.calculateTableDimensions(basedOn: size)
        let cells = grid.cells


        let cellTopLeft = grid.frameForCell(cells[0], basedOn: size)
        let cellMiddle = grid.frameForCell(cells[4], basedOn: size)
        let cellBottomRight = grid.frameForCell(cells[8], basedOn: size)
        let borderWidth = config.style.borderWidth

        XCTAssertEqual(cellTopLeft, CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0).insetBy(borderWidth: borderWidth))
        XCTAssertEqual(cellMiddle, CGRect(x: 100.0, y: 50.0, width: 100.0, height: 50.0).insetBy(borderWidth: borderWidth))
        XCTAssertEqual(cellBottomRight, CGRect(x: 200.0, y: 100.0, width: 100.0, height: 50.0).insetBy(borderWidth: borderWidth))
    }

    func testMergesRows() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])
        let size = CGSize(width: 300, height: 150)
        let grid = Grid(config: config, cells: generateCells(config: config))
        grid.calculateTableDimensions(basedOn: size)

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))

        grid.merge(cells:[cell11, cell21])

        let cellFrame = grid.frameForCell(cell11, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 100.0, y: 50.0, width: 100, height: 100).insetBy(borderWidth: config.style.borderWidth))
    }

    func testMergesColumnsWithFixedDimensions() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 150)
        grid.calculateTableDimensions(basedOn: size)

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        grid.merge(cells: [cell11, cell12])

        let cellFrame = grid.frameForCell(cell11, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 100.0, y: 50.0, width: 200, height: 50).insetBy(borderWidth: config.style.borderWidth))
    }

    func testMergesColumnsWithFractionalDimensions() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 150)
        grid.calculateTableDimensions(basedOn: size)

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        grid.merge(cells: [cell00, cell10])

        let cellFrame = grid.frameForCell(cell00, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 75.0, y: 50.0, width: 225, height: 50).insetBy(borderWidth: config.style.borderWidth))
    }

    func testMergesColumnsWithMixedDimensions() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 150)
        grid.calculateTableDimensions(basedOn: size)

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        grid.merge(cells: [cell00, cell10])

        let cellFrame = grid.frameForCell(cell00, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 75.0, y: 50.0, width: 250, height: 50).insetBy(borderWidth: config.style.borderWidth))
    }

    func testInsertRow() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 400)
        grid.calculateTableDimensions(basedOn: size)

        grid.insertRow(at: 1, frozenRowMaxIndex: nil, config: GridRowConfiguration(initialHeight: 20), cellDelegate: nil)
        XCTAssertEqual(grid.numberOfRows, 4)
        let newCells = grid.cells.filter { $0.rowSpan.contains(1) }
        XCTAssertEqual(newCells.count, 3)

        let expectedCellFrames = [
            (id: "{[1],[0]}", frame: CGRect(x: 0.0, y: 50.0, width: 75.0, height: 20.0)),
            (id: "{[1],[1]}", frame: CGRect(x: 75.0, y: 50.0, width: 100.0, height: 20.0)),
            (id: "{[1],[2]}", frame: CGRect(x: 175.0, y: 50.0, width: 150.0, height: 20.0)),
        ]

        for i in 0..<newCells.count {
            let cell = newCells[i]
            let frame = grid.frameForCell(cell, basedOn: size)
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame.insetBy(borderWidth: config.style.borderWidth))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testInsertRowUsesCustomEditorInit() {
        let expectation = functionExpectation()

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        expectation.expectedFulfillmentCount = config.numberOfColumns

        let editorInit = {
            expectation.fulfill()
            return EditorView(frame: .zero)
        }

        let grid = Grid(config: config, cells: generateCells(config: config), editorInitializer: editorInit)
        grid.insertRow(at: 1, frozenRowMaxIndex: nil, config: GridRowConfiguration(initialHeight: 20), cellDelegate: nil)
        let newCells = grid.cells.filter { $0.rowSpan.contains(1) }
        newCells.forEach { _ = $0.editor }

        waitForExpectations(timeout: 1.0)
    }

    func testInsertColumn() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 30),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 400)
        grid.calculateTableDimensions(basedOn: size)

        grid.insertColumn(at: 1, frozenColumnMaxIndex: nil, config: GridColumnConfiguration(width: .fractional(0.30)), cellDelegate: nil)
        XCTAssertEqual(grid.numberOfColumns, 4)
        let newCells = grid.cells.filter { $0.columnSpan.contains(1) }
        XCTAssertEqual(newCells.count, 3)

        let expectedCellFrames = [
            (id: "{[0],[1]}", frame: CGRect(x: 75.0, y: 0.0, width: 90.0, height: 30.0)),
            (id: "{[1],[1]}", frame: CGRect(x: 75.0, y: 30.0, width: 90.0, height: 40.0)),
            (id: "{[2],[1]}", frame: CGRect(x: 75.0, y: 70.0, width: 90.0, height: 50.0)),
        ]

        for i in 0..<newCells.count {
            let cell = newCells[i]
            let frame = grid.frameForCell(cell, basedOn: size)
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame.insetBy(borderWidth: config.style.borderWidth))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testInsertColumnUsesCustomEditorInit() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 30),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 50),
            ])

        expectation.expectedFulfillmentCount = config.numberOfColumns

        let editorInit = {
            expectation.fulfill()
            return EditorView(frame: .zero)
        }

        let grid = Grid(config: config, cells: generateCells(config: config), editorInitializer: editorInit)
        grid.insertColumn(at: 1, frozenColumnMaxIndex: nil, config: GridColumnConfiguration(width: .fractional(0.30)), cellDelegate: nil)
        XCTAssertEqual(grid.numberOfColumns, 4)
        let newCells = grid.cells.filter { $0.columnSpan.contains(1) }
        newCells.forEach { _ = $0.editor }

        waitForExpectations(timeout: 1.0)
    }

    func testDeletesRow() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 30),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 400)
        grid.calculateTableDimensions(basedOn: size)

        grid.deleteRow(at: 1)
        XCTAssertEqual(grid.numberOfRows, 2)
        let movedCells = grid.cells.filter { $0.rowSpan.contains(1) }

        let expectedCellFrames = [
            (id: "{[1],[0]}", frame: CGRect(x: 0.0, y: 30.0, width: 75.0, height: 50.0)),
            (id: "{[1],[1]}", frame: CGRect(x: 75.0, y: 30.0, width: 100.0, height: 50.0)),
            (id: "{[1],[2]}", frame: CGRect(x: 175.0, y: 30.0, width: 150.0, height: 50.0)),
        ]

        for i in 0..<movedCells.count {
            let cell = movedCells[i]
            let frame = grid.frameForCell(cell, basedOn: size)
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame.insetBy(borderWidth: config.style.borderWidth))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testDeletesColumn() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fractional(0.25)),
                GridColumnConfiguration(width: .fixed(100.0)),
                GridColumnConfiguration(width: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 30),
                GridRowConfiguration(initialHeight: 40),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let size = CGSize(width: 300, height: 400)
        grid.calculateTableDimensions(basedOn: size)

        grid.deleteColumn(at: 1)
        XCTAssertEqual(grid.numberOfColumns, 2)
        let movedCells = grid.cells.filter { $0.columnSpan.contains(1) }
        XCTAssertEqual(movedCells.count, 3)

        let expectedCellFrames = [
            (id: "{[0],[1]}", frame: CGRect(x: 75.0, y: 0.0, width: 150.0, height: 30.0)),
            (id: "{[1],[1]}", frame: CGRect(x: 75.0, y: 30.0, width: 150.0, height: 40.0)),
            (id: "{[2],[1]}", frame: CGRect(x: 75.0, y: 70.0, width: 150.0, height: 50.0)),
        ]

        for i in 0..<movedCells.count {
            let cell = movedCells[i]
            let frame = grid.frameForCell(cell, basedOn: size)
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame.insetBy(borderWidth: config.style.borderWidth))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

    }

    func testInsertsRowInMixedMergeCells() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 2))

        grid.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        grid.insertRow(at: 2, frozenRowMaxIndex: nil, config: GridRowConfiguration(initialHeight: 20), cellDelegate: nil)
        let expectedCellIDs = Set(["{[0],[0]}", "{[0],[1]}", "{[0],[2]}", "{[1],[0]}", "{[1, 2, 3],[1, 2]}", "{[3],[0]}", "{[2],[0]}"])
        let cells = Set(grid.cells.map { $0.id })

        XCTAssertEqual(cells.count, expectedCellIDs.count)
        XCTAssertEqual(expectedCellIDs.intersection(cells).count, cells.count)
    }

    func testInsertsColumnInMixedMergeCells() throws {
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

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        grid.merge(cells: [cell11, cell12])

        grid.insertColumn(at: 2, frozenColumnMaxIndex: nil, config: GridColumnConfiguration(width: .fixed(100)), cellDelegate: nil)

        print(grid.cells.map{ $0.id })
        let expectedCellIDs = Set(["{[0],[0]}", "{[0],[1]}", "{[0],[3]}", "{[1],[0]}", "{[1],[1, 2, 3]}", "{[2],[0]}", "{[2],[1]}", "{[2],[3]}", "{[0],[2]}", "{[2],[2]}"])
        let cells = Set(grid.cells.map { $0.id })

        XCTAssertEqual(cells.count, expectedCellIDs.count)
        XCTAssertEqual(expectedCellIDs.intersection(cells).count, cells.count)
    }

    func testIsMergableValid() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 2))

        let isMergeable = grid.isMergeable(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        XCTAssertTrue(isMergeable)
    }

    func testIsMergableInvalid() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 0))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 2))

        let isMergeable = grid.isMergeable(cells: [
            cell00,
            cell12,
            cell21,
            cell22
        ])

        XCTAssertFalse(isMergeable)
    }

    func testIsMergableValidWithMergedCells() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 2))

        grid.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])

        let cell01 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 1))
        let cell02 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 2))
        let mergedCell = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))

        let isMergeable = grid.isMergeable(cells: [
            cell01,
            cell02,
            mergedCell
        ])

        XCTAssertTrue(isMergeable)
    }

    func testIsMergableInvalidWithMergedCells() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 2))

        grid.merge(cells: [
            cell11,
            cell12,
            cell21,
            cell22
        ])


        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 0))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 0))
        let mergedCell = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))

        let isMergeable = grid.isMergeable(cells: [
            cell00,
            cell10,
            mergedCell
        ])

        XCTAssertFalse(isMergeable)
    }


    func testIsMergableInvalidWithUShapedSelection() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 0))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 0))
        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell02 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 2))

        let isMergeable = grid.isMergeable(cells: [
            cell00,
            cell10,
            cell11,
            cell12,
            cell02
        ])

        XCTAssertFalse(isMergeable)
    }

    func testIsMergableInvalidWithOShapedSelection() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
                GridColumnConfiguration(width: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
                GridRowConfiguration(initialHeight: 50),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 0))
        let cell01 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 1))
        let cell02 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 2))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 0))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))
        let cell20 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 0))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))
        let cell22 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 2))

        let isMergeable = grid.isMergeable(cells: [
            cell00,
            cell01,
            cell02,
            cell10,
            cell12,
            cell20,
            cell21,
            cell22,
        ])

        XCTAssertFalse(isMergeable)
    }

    private func generateCells(config: GridConfiguration) -> [GridCell] {
        var cells = [GridCell]()
        for row in 0..<config.numberOfRows {
            for column in 0..<config.numberOfColumns {
                let rowConfig = config.rowsConfiguration[row]
                let cell = GridCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    initialHeight: rowConfig.initialHeight
                )
                cells.append(cell)
            }
        }
        return cells
    }

    func testGetsPerfFrameForCell() {
        let generated = generateCells(numRows: 200, numColumns: 70)
        let table = Grid(config: generated.config, cells: generated.cells)
        let cells = table.cells

        let size = CGSize(width: 300, height: 150)


        measure {
            table.calculateTableDimensions(basedOn: size)
            makeCells(table, size: size)
        }
    }


    private func makeCells(_ table: Grid, size: CGSize) {
        for cell in table.cells {
            let frame = table.frameForCell(cell, basedOn: size)
            cell.frame = frame
        }
    }

    private func generateCells(numRows: Int,
                               numColumns: Int,
                               columnConfig: GridColumnConfiguration? = nil,
                               rowConfig: GridRowConfiguration? = nil) -> (config: GridConfiguration, cells: [GridCell]) {

        let columnConfiguration = columnConfig ?? GridColumnConfiguration(width: .fixed(100))
        let rowConfiguration = rowConfig ?? GridRowConfiguration(initialHeight: 50)

        let config = GridConfiguration(
            columnsConfiguration: [GridColumnConfiguration](repeating: columnConfiguration, count: numColumns),
            rowsConfiguration: [GridRowConfiguration](repeating: rowConfiguration, count: numRows)
        )
        var cells = [GridCell]()
        for row in 0..<config.numberOfRows {
            for column in 0..<config.numberOfColumns {
                let rowConfig = config.rowsConfiguration[row]
                let cell = GridCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    initialHeight: rowConfig.initialHeight
                )
                cells.append(cell)
            }
        }

        return (config: config, cells: cells)
    }
}

extension CGRect {
    func insetBy(borderWidth: CGFloat) -> CGRect {
        return inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -borderWidth, right: -borderWidth))
    }
}
