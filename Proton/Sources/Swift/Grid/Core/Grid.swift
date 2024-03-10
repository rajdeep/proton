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
    var isCollapsed: Bool
    let rowConfiguration: GridRowConfiguration
    let collapsedHeight: CGFloat

    var calculatedHeight: CGFloat {
        guard !isCollapsed else { return collapsedHeight }
        return currentHeight
    }

    init(rowConfiguration: GridRowConfiguration, isCollapsed: Bool = false, collapsedHeight: CGFloat) {
        self.rowConfiguration = rowConfiguration
        currentHeight = rowConfiguration.initialHeight
        self.isCollapsed = isCollapsed
        self.collapsedHeight = collapsedHeight
    }
}

protocol GridDelegate: AnyObject {
    var viewport: CGRect { get  }
    func grid(_ grid: Grid, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool
}

class Grid {

    private let config: GridConfiguration
    private let cellStore: GridCellStore
    private let editorInitializer: GridCell.EditorInitializer?

    var rowHeights = [GridRowDimension]()
    var columnWidths = [GridColumnDimension]()
    weak var delegate: GridDelegate?


    var currentRowHeights: [CGFloat] {
        rowHeights.map { $0.calculatedHeight }
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

    var viewport: CGRect? {
        delegate?.viewport
    }

    init(config: GridConfiguration, cells: [GridCell], editorInitializer: GridCell.EditorInitializer? = nil) {
        self.config = config
        self.editorInitializer = editorInitializer

        for column in config.columnsConfiguration {
            self.columnWidths.append(GridColumnDimension(width: column.width, collapsedWidth: config.collapsedColumnWidth))
        }

        for row in config.rowsConfiguration {
            self.rowHeights.append(GridRowDimension(rowConfiguration: row, collapsedHeight: config.collapsedRowHeight))
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

        let viewportWidth = viewport?.width ?? size.width

        if minColumnSpan > 0 {
            x = columnWidths[0..<minColumnSpan].reduce(0.0) { $0 + $1.value(basedOn: size.width, viewportWidth: viewportWidth)}
        }

        if minRowSpan > 0 {
            y = currentRowHeights[0..<minRowSpan].reduce(0.0, +)
        }

        var width: CGFloat = 0
        for col in cell.columnSpan {
            width += columnWidths[col].value(basedOn: size.width, viewportWidth: viewportWidth)
        }

        var height: CGFloat = 0
        for row in cell.rowSpan {
            height += currentRowHeights[row]
        }
        // Inset is required to create overlapping borders for cells
        // In absence of this code, the internal border appears twice as thick as outer as
        // the layer borders do not perfectly overlap
        let inset = -config.style.borderWidth
        let frame = CGRect(x: x, y: y, width: width, height: height).inset(by: UIEdgeInsets(top: 0, left: 0, bottom: inset, right: inset))
        return frame
    }

    func sizeThatFits(size: CGSize) -> CGSize {
        let viewportWidth = viewport?.width ?? size.width
        let width = columnWidths.reduce(0.0) { $0 + $1.value(basedOn: size.width, viewportWidth: viewportWidth)} + config.style.borderWidth
        // Account for additional height equal to borders from inset created when calculating the fames for cells
        let height = currentRowHeights.reduce(0.0, +) + config.style.borderWidth
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

    func isMergeable(cells: [GridCell]) -> Bool {
        guard cells.count > 1 else { return false }
        let columns = Set(cells.flatMap { $0.columnSpan })
        let rows = Set(cells.flatMap { $0.rowSpan })

        for r in rows {
            for c in columns {
                if cells.first(where: { $0.rowSpan.contains(r) && $0.columnSpan.contains(c)}) == nil {
                    return false
                }
            }
        }

        return true
    }


    func changeColumnWidth(index: Int, totalWidth: CGFloat, delta: CGFloat) {
        let viewportWidth = viewport?.width ?? totalWidth
        let proposedWidth = columnWidths[index].value(basedOn: totalWidth, viewportWidth: viewportWidth) + delta
        guard index < columnWidths.count,
              delegate?.grid(self, shouldChangeColumnWidth: proposedWidth, for: index) ?? true else { return }
        columnWidths[index].width = .fixed(columnWidths[index].value(basedOn: totalWidth, viewportWidth: viewportWidth) + delta)
    }

    func changeRowHeight(index: Int, delta: CGFloat) {
        guard index < rowHeights.count else { return }

        guard rowHeights[index].rowConfiguration.initialHeight > rowHeights[index].currentHeight + delta else {
            return
        }

        rowHeights[index].currentHeight = rowHeights[index].currentHeight + delta
    }

    @discardableResult
    func merge(cells: [GridCell]) -> GridCell? {
        guard isMergeable(cells: cells) else { return nil }
        let firstCell = cells[0]
        for i in 1..<cells.count {
            merge(cell: firstCell, other: cells[i])
        }
        return firstCell
    }

    private func merge(cell: GridCell, other: GridCell) {
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

    @discardableResult
    func split(cell: GridCell) -> [GridCell] {
        guard cell.isSplittable,
              cells.contains(where: { $0.id == cell.id }) else { return []}

        guard let minRowIndex = cell.rowSpan.min(),
              let maxRowIndex = cell.rowSpan.max(),
              let minColumnIndex = cell.columnSpan.min(),
              let maxColumnIndex = cell.columnSpan.max() else { return []}

        var newCells = [GridCell]()
        for row in minRowIndex ... maxRowIndex {
            for col in minColumnIndex ... maxColumnIndex {
                let c = GridCell(
                    rowSpan: [row],
                    columnSpan: [col],
                    initialHeight: cell.initialHeight,
                    ignoresOptimizedInit: true,
                    editorInitializer: editorInitializer
                )
                c.delegate = cell.delegate
                newCells.append(c)
            }
        }

        let firstCell = newCells.remove(at: 0)
        cell.rowSpan = firstCell.rowSpan
        cell.columnSpan = firstCell.columnSpan

        cellStore.addCells(newCells)
        return newCells
    }

    @discardableResult
    func insertRow(at index: Int, frozenRowMaxIndex: Int?, config: GridRowConfiguration, cellDelegate: GridCellDelegate?) -> Result<[GridCell], GridViewError> {
        var sanitizedIndex = index
        if sanitizedIndex < 0 {
            sanitizedIndex = 0
        } else if sanitizedIndex > numberOfRows {
            sanitizedIndex = numberOfRows
        }

        if let frozenRowMaxIndex = frozenRowMaxIndex,
           sanitizedIndex <= frozenRowMaxIndex {
            return .failure(.failedToInsertInFrozenRows)
        }


        if sanitizedIndex < numberOfRows {
            cellStore.moveCellRowIndex(from: sanitizedIndex, by: 1)
        }
        rowHeights.insert(GridRowDimension(rowConfiguration: config, collapsedHeight: self.config.collapsedRowHeight), at: sanitizedIndex)
        var cells = [GridCell]()
        for c in 0..<numberOfColumns {
            let cell = GridCell(
                rowSpan: [sanitizedIndex],
                columnSpan: [c],
                initialHeight: config.initialHeight,
                style: config.style,
                editorInitializer: editorInitializer)

            if cellAt(rowIndex: sanitizedIndex, columnIndex: c) != nil {
                continue
            }
            cell.delegate = cellDelegate
            cellStore.addCell(cell)
            cells.append(cell)
        }
        return .success(cells)
    }

    @discardableResult
    func insertColumn(at index: Int, frozenColumnMaxIndex: Int?, config: GridColumnConfiguration, cellDelegate: GridCellDelegate?) -> Result<[GridCell], GridViewError> {
        var sanitizedIndex = index
        if sanitizedIndex < 0 {
            sanitizedIndex = 0
        } else if sanitizedIndex > numberOfColumns {
            sanitizedIndex = numberOfColumns
        }

        if let frozenColumnMaxIndex = frozenColumnMaxIndex,
           sanitizedIndex <= frozenColumnMaxIndex {
            return .failure(.failedToInsertInFrozenColumns)
        }

        if sanitizedIndex < numberOfColumns {
            cellStore.moveCellColumnIndex(from: sanitizedIndex, by: 1)
        }
        columnWidths.insert(GridColumnDimension(width: config.width, collapsedWidth: self.config.collapsedColumnWidth), at: sanitizedIndex)

        var cells = [GridCell]()
        for r in 0..<numberOfRows {
            let cell = GridCell(
                rowSpan: [r],
                columnSpan: [sanitizedIndex],
                initialHeight: rowHeights[r].rowConfiguration.initialHeight,
                style: config.style,
                editorInitializer: editorInitializer
            )

            if cellAt(rowIndex: r, columnIndex: sanitizedIndex) != nil {
                continue
            }
            cell.delegate = cellDelegate
            cellStore.addCell(cell)
            cells.append(cell)
        }
        return .success(cells)
    }

    func deleteRow(at index: Int) {
        guard rowHeights.count > 1 else { return }
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

        cellsToRemove.forEach { $0.contentView.removeFromSuperview() }
        cellStore.deleteCells(cellsToRemove)
        for cell in cellsToUpdate {
            cell.rowSpan.removeAll{ $0 == index }
            cell.rowSpan = cell.rowSpan.map { $0 < index ? $0 : $0 - 1 }
        }
        rowHeights.remove(at: index)

        if index < numberOfRows {
            cellStore.moveCellRowIndex(from: index + 1, by: -1)
        }
    }

    func deleteColumn(at index: Int) {
        guard columnWidths.count > 1 else { return }
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

        cellsToRemove.forEach { $0.contentView.removeFromSuperview() }
        cellStore.deleteCells(cellsToRemove)
        for cell in cellsToUpdate {
            cell.columnSpan.removeAll{ $0 == index }
            cell.columnSpan = cell.columnSpan.map { $0 < index ? $0 : $0 - 1 }
        }
        columnWidths.remove(at: index)

        if index < numberOfColumns {
            cellStore.moveCellColumnIndex(from: index + 1, by: -1)
        }

    }

    func collapseRow(at index: Int) {
        rowHeights[index].isCollapsed = true
    }

    func expandRow(at index: Int) {
        rowHeights[index].isCollapsed = false
    }

    func collapseColumn(at index: Int) {
        columnWidths[index].isCollapsed = true
        // Hide editor failing which resizing column ends up elongating column based on content in cell
        cells.forEach {
            if $0.columnSpan.contains(index) {
                $0.hideEditor()
            }
        }
    }

    func expandColumn(at index: Int) {
        columnWidths[index].isCollapsed = false
        cells.forEach {
            if $0.columnSpan.contains(index) {
                $0.showEditor()
            }
        }
    }

    func getCollapsedRowIndices() -> [Int] {
        return rowHeights.indices.filter { rowHeights[$0].isCollapsed }
    }

    func getCollapsedColumnIndices() -> [Int] {
        return columnWidths.indices.filter { columnWidths[$0].isCollapsed }
    }
}

public enum GridViewError: Error {
    case failedToInsertInFrozenRows
    case failedToInsertInFrozenColumns
}
