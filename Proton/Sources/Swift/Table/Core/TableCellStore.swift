//
//  TableCellStore.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/4/2024.
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

class TableCellStore {
    private(set) var cells = [TableCell]()

    init(cells: [TableCell]) {
        self.cells = cells
    }

    var numberOfColumns: Int {
        guard let columns = cells.flatMap({ $0.columnSpan }).max() else { return 0 }
        return columns + 1
    }

    var numberOfRows: Int {
        guard let rows = cells.flatMap({ $0.rowSpan }).max() else { return 0 }
        return rows + 1
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> TableCell? {
        return cells.first(where: { $0.rowSpan.contains(rowIndex) && $0.columnSpan.contains(columnIndex) })
    }

    func deleteCellAt(index: Int) {
        let cell = cells[index]
        cell.removeContentView()
        cells.remove(at: index)

    }

    func addCells(_ newCells: [TableCell]) {
        cells.append(contentsOf: newCells)
    }

    func addCell(_ cell: TableCell) {
        cells.append(cell)
    }

    func deleteCells(_ cellsToDelete: [TableCell]) {
        //TODO: fix
//        cells = cells.filter({ !cellsToDelete.contains($0) })
    }

    func moveCellRowIndex(from index: Int, by step: Int) {
        for cell in cells {
            if cell.isSplittable,
               let min = cell.rowSpan.min(),
               min < index,
               let max = cell.rowSpan.max(),
               max >= index {
                cell.rowSpan.append(max + 1)
            } else {
                    for i in 0..<cell.rowSpan.count {
                        if cell.rowSpan[i] >= index {
                            cell.rowSpan[i] += step
                        }
                    }
                }
            }
    }

    func moveCellColumnIndex(from index: Int, by step: Int) {
        for cell in cells {
            if cell.isSplittable,
               let min = cell.columnSpan.min(),
               min < index,
               let max = cell.columnSpan.max(),
               max >= index {
                cell.columnSpan.append(max + 1)
            } else {
                for i in 0..<cell.columnSpan.count {
                    if cell.columnSpan[i] >= index {
                        cell.columnSpan[i] += step
                    }
                }
            }
        }
    }
}
