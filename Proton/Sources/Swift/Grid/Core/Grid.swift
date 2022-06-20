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

class GridRowDimension {
    var currentHeight: CGFloat
    let rowConfiguration: GridRowConfiguration

    init(rowConfiguration: GridRowConfiguration) {
        self.rowConfiguration = rowConfiguration
        currentHeight = rowConfiguration.minRowHeight
    }
}

class Grid {

    private let config: GridConfiguration
    private let cellStore: GridCellStore

    var rowHeights = [GridRowDimension]()
    var columnWidths = [GridColumnDimension]()

    var currentRowHeights: [CGFloat] {
        rowHeights.map { $0.currentHeight }
    }

    var cells: [GridCell] {
        cellStore.cells
    }

    var numberOfColumns: Int {
        columnWidths.count
    }

    var numberOfRows: Int {
        rowHeights.count
    }

    init(config: GridConfiguration, cells: [GridCell]) {
        self.config = config

        for column in config.columnsConfiguration {
            self.columnWidths.append(column.dimension)
        }

        for row in config.rowsConfiguration {
            self.rowHeights.append(GridRowDimension(rowConfiguration: row))
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
            y = currentRowHeights[0..<minRowSpan].reduce(0.0, +)
        }

        var width: CGFloat = 0
        for col in cell.columnSpan {
            width += columnWidths[col].value(basedOn: size.width)
        }

        var height: CGFloat = 0
        for row in cell.rowSpan {
            height += currentRowHeights[row]
        }
        let frame = CGRect(x: x, y: y, width: width, height: height)
        cell.cachedFrame = frame
        return frame
    }

    func sizeThatFits(size: CGSize) -> CGSize {
        let width = columnWidths.reduce(0.0) { $0 + $1.value(basedOn: size.width)}
        let height = currentRowHeights.reduce(0.0, +)
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

    func merge(cells: [GridCell]) {
        guard cells.isEmpty == false else { return }
        let firstCell = cells[0]
        for i in 1..<cells.count {
            merge(cell: firstCell, other: cells[i])
        }
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

    func split(cell: GridCell) {
        guard cell.isSplittable,
              cells.contains(where: { $0.id == cell.id }) else { return }

        guard let minRowIndex = cell.rowSpan.min(),
              let maxRowIndex = cell.rowSpan.max(),
              let minColumnIndex = cell.columnSpan.min(),
              let maxColumnIndex = cell.columnSpan.max() else { return }

        var newCells = [GridCell]()
        for row in minRowIndex ... maxRowIndex {
            for col in minColumnIndex ... maxColumnIndex {
                let c = GridCell(rowSpan: [row], columnSpan: [col], minHeight: cell.minHeight, maxHeight: cell.maxHeight)
                newCells.append(c)
            }
        }

        let firstCell = newCells.remove(at: 0)
        cell.rowSpan = firstCell.rowSpan
        cell.columnSpan = firstCell.columnSpan

        cellStore.addCells(newCells)
    }

    func insertRow(at index: Int, config: GridRowConfiguration) {
        if index < numberOfRows {
            cellStore.moveCellRowIndex(from: index, by: 1)
        }
        rowHeights.insert(GridRowDimension(rowConfiguration: config), at: index)

        for c in 0..<numberOfColumns {
            let cell = GridCell(
                rowSpan: [index],
                columnSpan: [c],
                minHeight: config.minRowHeight,
                maxHeight: config.maxRowHeight)

            if cellAt(rowIndex: index, columnIndex: c) != nil {
                continue
            }

            cellStore.addCell(cell)
        }
    }

    func insertColumn(at index: Int, config: GridColumnConfiguration) {
        if index < numberOfColumns {
            cellStore.moveCellColumnIndex(from: index, by: 1)
        }
        columnWidths.insert(config.dimension, at: index)

        for r in 0..<numberOfRows {
            let cell = GridCell(
                rowSpan: [r],
                columnSpan: [index],
                minHeight: rowHeights[r].rowConfiguration.minRowHeight,
                maxHeight: rowHeights[r].rowConfiguration.maxRowHeight)

            if cellAt(rowIndex: r, columnIndex: index) != nil {
                continue
            }
            cellStore.addCell(cell)
        }
    }

    func deleteRow(at index: Int) {
        var cellsToRemove = [GridCell]()
        var cellsToUpdate = [GridCell]()

        for cell in cells {
            if cell.rowSpan.contains(index) {
                if cell.isSplittable {
                    cellsToUpdate.append(cell)
                } else {
                    cellsToRemove.append(cell)
                }
            }
        }

        cellStore.deleteCells(cellsToRemove)
        for cell in cellsToUpdate {
            cell.columnSpan.removeAll{ $0 == index }
            cell.columnSpan = cell.columnSpan.map { $0 < index ? $0 : $0 - 1 }
        }

        if index < numberOfRows {
            cellStore.moveCellRowIndex(from: index, by: -1)
            rowHeights.remove(at: index)
        }
    }

    func deleteColumn(at index: Int) {
        var cellsToRemove = [GridCell]()
        var cellsToUpdate = [GridCell]()

        for cell in cells {
            if cell.columnSpan.contains(index) {
                if cell.isSplittable {
                    cellsToUpdate.append(cell)
                } else {
                    cellsToRemove.append(cell)
                }
            }
        }

        cellStore.deleteCells(cellsToRemove)
        for cell in cellsToUpdate {
            cell.rowSpan.removeAll{ $0 == index }
            cell.rowSpan = cell.rowSpan.map { $0 < index ? $0 : $0 - 1 }
        }

        if index < numberOfColumns {
            cellStore.moveCellColumnIndex(from: index, by: -1)
            columnWidths.remove(at: index)
        }
    }
}
