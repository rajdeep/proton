//
//  Table.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/8/2024.
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
import UIKit

protocol TableDelegate: AnyObject {
    var viewport: CGRect { get  }
    func table(_ table: Table, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool
}

class Table {

    private let config: GridConfiguration
    private let cellStore: TableCellStore
    private let editorInitializer: TableCell.EditorInitializer?
    private var cellXPositions = [Int: CGFloat]()
    private var cellYPositions = [Int: CGFloat]()

    var rowHeights = [GridRowDimension]()
    var columnWidths = [GridColumnDimension]()
    weak var delegate: TableDelegate?

    var currentRowHeights: [CGFloat] {
        rowHeights.map { $0.calculatedHeight }
    }

    var cells: [TableCell] {
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

    var size: CGSize {
        guard let lastCell = cellAt(rowIndex: numberOfRows - 1, columnIndex: numberOfColumns - 1) else {
            return .zero
        }
        let width = lastCell.frame.maxX
        let height = lastCell.frame.maxY
        return CGSize(width: width, height: height)
    }

    init(config: GridConfiguration, cells: [TableCell], editorInitializer: TableCell.EditorInitializer? = nil) {
        self.config = config
        self.editorInitializer = editorInitializer

        for column in config.columnsConfiguration {
            self.columnWidths.append(GridColumnDimension(width: column.width, collapsedWidth: config.collapsedColumnWidth))
        }

        for row in config.rowsConfiguration {
            self.rowHeights.append(GridRowDimension(rowConfiguration: row, collapsedHeight: config.collapsedRowHeight))
        }
        self.cellStore = TableCellStore(cells: cells)
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> TableCell? {
        return cellStore.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    func resetRowHeights() {
        for i in 0..<rowHeights.count {
            rowHeights[i].currentHeight = rowHeights[i].rowConfiguration.initialHeight
        }
    }

    func calculateTableDimensions(basedOn size: CGSize) {
        let viewportWidth = viewport?.width ?? size.width
        var cumulativeX: CGFloat = 0

        for (i, colWidth) in columnWidths.enumerated() {
            let width = colWidth.value(basedOn: size.width, viewportWidth: viewportWidth)
            cellXPositions[i] = cumulativeX
            cumulativeX += width
        }

        var cumulativeY: CGFloat = 0
        for (i, rowHeight) in currentRowHeights.enumerated() {
            cellYPositions[i] = cumulativeY
            cumulativeY += rowHeight
        }
    }

    func updateCellFrames(size: CGSize, onCellFrameUpdate: ((TableCell) -> Void)) {
        calculateTableDimensions(basedOn: size)
        for cell in cells {
            let frame = frameForCell(cell, basedOn: size)
            cell.frame = frame
            onCellFrameUpdate(cell)
        }
    }

    func cellsIn(rect: CGRect, offset: CGPoint) -> [TableCell] {
        let sortedKeysX = cellXPositions.sorted { $0.value < $1.value }.map { $0.key }
        let sortedKeysY = cellYPositions.sorted { $0.value < $1.value }.map { $0.key }

        guard let colMin = sortedKeysX.last(where: { cellXPositions[$0] ?? 0 <= rect.minX }),
              let colMax = sortedKeysX.first(where: { cellXPositions[$0] ?? 0 >= rect.maxX }),
              let rowMin = sortedKeysY.last(where: { cellYPositions[$0] ?? 0 <= rect.minY }),
              let rowMax = sortedKeysY.first(where: { cellYPositions[$0] ?? 0 >= rect.maxY }) else {
            return []
        }

        let columns = Array(colMin...colMax)
        let rows = Array((rowMin - 1)..<rowMax)

        return cells.filter({
            $0.rowSpan.contains { rows.contains($0) }
            && $0.columnSpan.contains { columns.contains($0) }
        })
    }

    func frameForCell(_ cell: TableCell, basedOn size: CGSize) -> CGRect {
        var x: CGFloat = 0
        var y: CGFloat = 0

        guard let minColumnSpan = cell.columnSpan.min(),
              let minRowSpan = cell.rowSpan.min() else {
            return .zero
        }

        let viewportWidth = viewport?.width ?? size.width

        if minColumnSpan > 0 {
            x = cellXPositions[minColumnSpan] ?? 0
        }

        if minRowSpan > 0 {
            y = cellYPositions[minRowSpan] ?? 0
        }

        let width = cell.columnSpan.reduce(into: 0.0) { result, col in
            result += columnWidths[col].value(basedOn: size.width, viewportWidth: viewportWidth)
        }

        let height = cell.rowSpan.reduce(into: 0.0) { result, row in
            result += rowHeights[row].currentHeight 
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

    func maxContentHeightCellForRow(at index: Int) -> TableCell? {
        //TODO: account for merged rows
        let cells = cellStore.cells.filter { $0.rowSpan.contains(index) }
        return cells.max(by: {$0.contentSize.height < $1.contentSize.height })

//        var maxHeightCell: TableCell?
//        for cell in cells {
//            if cell.contentSize.height > maxHeightCell?.contentSize.height ?? 0 {
//                maxHeightCell = cell
//            }
//        }
//        return maxHeightCell
    }

    func isMergeable(cells: [TableCell]) -> Bool {
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
              delegate?.table(self, shouldChangeColumnWidth: proposedWidth, for: index) ?? true else { return }
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
    func merge(cells: [TableCell]) -> TableCell? {
        guard isMergeable(cells: cells) else { return nil }
        let firstCell = cells[0]
        for i in 1..<cells.count {
            merge(cell: firstCell, other: cells[i])
        }
        return firstCell
    }

    private func merge(cell: TableCell, other: TableCell) {
        guard let _ = cellStore.cells.firstIndex(where: { $0.id == cell.id }),
              let otherIndex = cellStore.cells.firstIndex(where: { $0.id == other.id }) else {
            return
        }

        cell.rowSpan = Array(Set(cell.rowSpan).union(other.rowSpan)).sorted()
        cell.columnSpan = Array(Set(cell.columnSpan).union(other.columnSpan)).sorted()

        // TODO: fix
//        cell.editor.replaceCharacters(in: cell.editor.textEndRange, with: " ")
//        cell.editor.replaceCharacters(in: cell.editor.textEndRange, with: other.editor.attributedText)

        cellStore.deleteCellAt(index: otherIndex)
    }

    @discardableResult
    func split(cell: TableCell) -> [TableCell] {
        guard cell.isSplittable,
              cells.contains(where: { $0.id == cell.id }) else { return []}

        guard let minRowIndex = cell.rowSpan.min(),
              let maxRowIndex = cell.rowSpan.max(),
              let minColumnIndex = cell.columnSpan.min(),
              let maxColumnIndex = cell.columnSpan.max() else { return []}

        var newCells = [TableCell]()
        for row in minRowIndex ... maxRowIndex {
            for col in minColumnIndex ... maxColumnIndex {
                let c = TableCell(
                    rowSpan: [row],
                    columnSpan: [col],
                    initialHeight: cell.initialHeight,
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
    func insertRow(at index: Int, frozenRowMaxIndex: Int?, config: GridRowConfiguration, cellDelegate: TableCellDelegate?) -> Result<[TableCell], TableViewError> {
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
        var cells = [TableCell]()
        for c in 0..<numberOfColumns {
            let cell = TableCell(
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
    func insertColumn(at index: Int, frozenColumnMaxIndex: Int?, config: GridColumnConfiguration, cellDelegate: TableCellDelegate?) -> Result<[TableCell], TableViewError> {
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

        var cells = [TableCell]()
        for r in 0..<numberOfRows {
            let cell = TableCell(
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
        var cellsToRemove = [TableCell]()
        var cellsToUpdate = [TableCell]()

        for cell in cells {
            if cell.rowSpan.contains(index) {
                if cell.isSplittable {
                    cellsToUpdate.append(cell)
                } else {
                    cellsToRemove.append(cell)
                }
            }
        }

        cellsToRemove.forEach { $0.removeContentView() }
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
        var cellsToRemove = [TableCell]()
        var cellsToUpdate = [TableCell]()

        for cell in cells {
            if cell.columnSpan.contains(index) {
                if cell.isSplittable {
                    cellsToUpdate.append(cell)
                } else {
                    cellsToRemove.append(cell)
                }
            }
        }

        cellsToRemove.forEach { $0.removeContentView() }
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

public enum TableViewError: Error {
    case failedToInsertInFrozenRows
    case failedToInsertInFrozenColumns
}
