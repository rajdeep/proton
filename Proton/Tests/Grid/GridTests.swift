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
//        XCTAssertEqual(grid.size, CGSize(width: 200, height: 150))
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
