//
//  TableTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/4/24.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
//
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

class TableTests: XCTestCase {
    func testGetsFrameForCell() {
        let generated = generateCells(numRows: 200, numColumns: 70)
        let table = Table(config: generated.config, cells: generated.cells)
        let cells = table.cells

        let size = CGSize(width: 300, height: 150)


        measure {
            table.calculateTableDimensions(basedOn: size)
            makeCells(table, size: size)
        }
    }

    private func makeCells(_ table: Table, size: CGSize) {
        for cell in table.cells {
            let frame = table.frameForCell(cell, basedOn: size)
            cell.frame = frame
        }
    }

    private func generateCells(numRows: Int,
                               numColumns: Int,
                               columnConfig: GridColumnConfiguration? = nil,
                               rowConfig: GridRowConfiguration? = nil) -> (config: GridConfiguration, cells: [TableCell]) {

        let columnConfiguration = columnConfig ?? GridColumnConfiguration(width: .fixed(100))
        let rowConfiguration = rowConfig ?? GridRowConfiguration(initialHeight: 50)

        let config = GridConfiguration(
            columnsConfiguration: [GridColumnConfiguration](repeating: columnConfiguration, count: numColumns),
            rowsConfiguration: [GridRowConfiguration](repeating: rowConfiguration, count: numRows)
        )
        var cells = [TableCell]()
        for row in 0..<config.numberOfRows {
            for column in 0..<config.numberOfColumns {
                let rowConfig = config.rowsConfiguration[row]
                let cell = TableCell(
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
