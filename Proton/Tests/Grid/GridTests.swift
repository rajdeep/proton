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
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
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

    func testSome() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 0, columnIndex: 0))
        let cell01 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 0))

        print(grid.frameForCell(cell00, basedOn: CGSize(width: 300, height: 300)))
        print(grid.frameForCell(cell01, basedOn: CGSize(width: 300, height: 300)))
    }

    func testGetsFrameForCell() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        let cells = grid.cells

        let size = CGSize(width: 300, height: 150)
        let cellTopLeft = grid.frameForCell(cells[0], basedOn: size)
        let cellMiddle = grid.frameForCell(cells[4], basedOn: size)
        let cellBottomRight = grid.frameForCell(cells[8], basedOn: size)

        XCTAssertEqual(cellTopLeft, CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0))
        XCTAssertEqual(cellMiddle, CGRect(x: 100.0, y: 50.0, width: 100.0, height: 50.0))
        XCTAssertEqual(cellBottomRight, CGRect(x: 200.0, y: 100.0, width: 100.0, height: 50.0))
    }

    func testMergesRows() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell21 = try XCTUnwrap(grid.cellAt(rowIndex: 2, columnIndex: 1))

        let size = CGSize(width: 300, height: 150)
        grid.merge(cells:[cell11, cell21])

        let cellFrame = grid.frameForCell(cell11, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 100.0, y: 50.0, width: 100, height: 100))
    }

    func testMergesColumnsWithFixedDimensions() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        let size = CGSize(width: 300, height: 150)
        grid.merge(cells: [cell11, cell12])

        let cellFrame = grid.frameForCell(cell11, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 100.0, y: 50.0, width: 200, height: 50))
    }

    func testMergesColumnsWithFractionalDimensions() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        let size = CGSize(width: 300, height: 150)
        grid.merge(cells: [cell00, cell10])

        let cellFrame = grid.frameForCell(cell00, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 75.0, y: 50.0, width: 225, height: 50))
    }

    func testMergesColumnsWithMixedDimensions() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fixed(100.0)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell00 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell10 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        let size = CGSize(width: 300, height: 150)
        grid.merge(cells: [cell00, cell10])

        let cellFrame = grid.frameForCell(cell00, basedOn: size)
        XCTAssertEqual(cellFrame, CGRect(x: 75.0, y: 50.0, width: 250, height: 50))
    }

    func testInsertRow() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fixed(100.0)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        grid.insertRow(at: 1, config: GridRowConfiguration(minRowHeight: 20, maxRowHeight: 100))
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
            let frame = grid.frameForCell(cell, basedOn: CGSize(width: 300, height: 400))
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testInsertColumn() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fixed(100.0)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 30, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
        grid.insertColumn(at: 1, config: GridColumnConfiguration(dimension: .fractional(0.30)))
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
            let frame = grid.frameForCell(cell, basedOn: CGSize(width: 300, height: 400))
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testDeletesRow() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fixed(100.0)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 30, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
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
            let frame = grid.frameForCell(cell, basedOn: CGSize(width: 300, height: 400))
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testDeletesColumn() {
        let expectation = functionExpectation()
        expectation.expectedFulfillmentCount = 3

        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fixed(100.0)),
                GridColumnConfiguration(dimension: .fractional(0.50)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 30, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))
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
            let frame = grid.frameForCell(cell, basedOn: CGSize(width: 300, height: 400))
            let expectedCellFrame = expectedCellFrames[i]
            XCTAssertEqual(cell.id, expectedCellFrame.id)
            XCTAssertEqual(frame, expectedCellFrame.frame)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

    }

    func testInsertsRowInMixedMergeCells() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
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

        grid.insertRow(at: 2, config: GridRowConfiguration(minRowHeight: 20, maxRowHeight: 20))
        let expectedCellIDs = Set(["{[0],[0]}", "{[0],[1]}", "{[0],[2]}", "{[1],[0]}", "{[1, 2, 3],[1, 2]}", "{[3],[0]}", "{[2],[0]}"])
        let cells = Set(grid.cells.map { $0.id })

        XCTAssertEqual(cells.count, expectedCellIDs.count)
        XCTAssertEqual(expectedCellIDs.intersection(cells).count, cells.count)
    }

    func testInsertsColumnInMixedMergeCells() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])

        let grid = Grid(config: config, cells: generateCells(config: config))

        let cell11 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 1))
        let cell12 = try XCTUnwrap(grid.cellAt(rowIndex: 1, columnIndex: 2))

        grid.merge(cells: [cell11, cell12])

        grid.insertColumn(at: 2, config: GridColumnConfiguration(dimension: .fixed(100)))

        print(grid.cells.map{ $0.id })
        let expectedCellIDs = Set(["{[0],[0]}", "{[0],[1]}", "{[0],[3]}", "{[1],[0]}", "{[1],[1, 2, 3]}", "{[2],[0]}", "{[2],[1]}", "{[2],[3]}", "{[0],[2]}", "{[2],[2]}"])
        let cells = Set(grid.cells.map { $0.id })

        XCTAssertEqual(cells.count, expectedCellIDs.count)
        XCTAssertEqual(expectedCellIDs.intersection(cells).count, cells.count)
    }

    func testIsMergableValid() throws {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
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
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
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
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
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
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
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

    private func generateCells(config: GridConfiguration) -> [GridCell] {
        var cells = [GridCell]()
        for row in 0..<config.numberOfRows {
            for column in 0..<config.numberOfColumns {
                let rowConfig = config.rowsConfiguration[row]
                let cell = GridCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    minHeight: rowConfig.minRowHeight,
                    maxHeight: rowConfig.maxRowHeight
                )
                cells.append(cell)
            }
        }
        return cells
    }
}
