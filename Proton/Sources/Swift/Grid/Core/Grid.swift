//
//  Grid.swift
//  Proton
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
import UIKit

class GridCellStore {
    private(set) var cells = [GridCell]()

    init(cells: [GridCell]) {
        self.cells = cells
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> GridCell? {
        return cells.first(where: { $0.rowSpan.contains(rowIndex) && $0.columnSpan.contains(columnIndex) })
    }

    func deleteCellAt(index: Int) {
        let cell = cells[index]
        cell.contentView.removeFromSuperview()
        cells.remove(at: index)

    }
}

class Grid {

    private let config: GridConfiguration
    private let cellStore: GridCellStore

    var rowHeights = [CGFloat]()
    var columnWidths = [GridColumnDimension]()

    var cells: [GridCell] {
        cellStore.cells
    }

    init(config: GridConfiguration, cells: [GridCell]) {
        self.config = config

        for column in config.columnsConfiguration {
            self.columnWidths.append(column.dimension)
        }

        for row in config.rowsConfiguration {
            self.rowHeights.append(row.minRowHeight)
        }
        self.cellStore = GridCellStore(cells: cells)
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> GridCell? {
        return cellStore.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    func frameForCell(_ cell: GridCell, basedOn size: CGSize) -> CGRect {
        var x: CGFloat = 0
        var y: CGFloat = 0

        guard let minColumnSpan = cell.columnSpan.min(),
              let minRowSpan = cell.rowSpan.min() else {
            return .zero
        }

        if minColumnSpan > 0 {
            x = columnWidths[0..<minColumnSpan].reduce(0.0) { $0 + $1.value(basedOn: size.width)}
        }

        if minRowSpan > 0 {
            y = rowHeights[0..<minRowSpan].reduce(0.0, +)
        }

        var width: CGFloat = 0
        for col in cell.columnSpan {
            width += columnWidths[col].value(basedOn: size.width)
        }

        var height: CGFloat = 0
        for row in cell.rowSpan {
            height += rowHeights[row]
        }
        let frame = CGRect(x: x, y: y, width: width, height: height)
        cell.cachedFrame = frame
        return frame
    }

    func sizeThatFits(size: CGSize) -> CGSize {
        let width = columnWidths.reduce(0.0) { $0 + $1.value(basedOn: size.width)}
        let height = rowHeights.reduce(0.0, +)
        return CGSize(width: width, height: height)
    }

    func maxContentHeightCellForRow(at index: Int) -> GridCell? {
        //TODO: account for merged rows
        let cells = cellStore.cells.filter { $0.rowSpan.contains(index) }
        var maxHeightCell: GridCell?
        for cell in cells {
            if cell.contentSize.height > maxHeightCell?.contentSize.height ?? 0 {
                maxHeightCell = cell
            }
        }
        return maxHeightCell
    }

    func merge(cell: GridCell, other: GridCell) {
        //TODO: Validate if columns can be merged i.e. side by side/up and down
        guard let _ = cellStore.cells.firstIndex(where: { $0.id == cell.id }),
              let otherIndex = cellStore.cells.firstIndex(where: { $0.id == other.id }) else {
            return
        }

        cell.rowSpan = Array(Set(cell.rowSpan).union(other.rowSpan)).sorted()
        cell.columnSpan = Array(Set(cell.columnSpan).union(other.columnSpan)).sorted()

        cell.editor.replaceCharacters(in: cell.editor.textEndRange, with: " ")
        cell.editor.replaceCharacters(in: cell.editor.textEndRange, with: other.editor.attributedText)

        cellStore.deleteCellAt(index: otherIndex)
    }
}
