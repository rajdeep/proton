//
//  TableContentView.swift
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
import Foundation
import UIKit

protocol TableContentViewDelegate: AnyObject {
    var viewport: CGRect? { get }
    var containerScrollView: UIScrollView? { get }

    var cellsInViewport: [TableCell] { get }

    func tableContentView(_ tableContentView: TableContentView, didChangeBounds bounds: CGRect, oldBounds: CGRect)
    func tableContentView(_ tableContentView: TableContentView, didCompleteLayoutWithBounds bounds: CGRect)
    func tableContentView(_ tableContentView: TableContentView, didLayoutCell cell: TableCell)

    func tableContentView(_ tableContentView: TableContentView, didReceiveFocusAt range: NSRange, in cell: TableCell)
    func tableContentView(_ tableContentView: TableContentView, didLoseFocusFrom range: NSRange, in cell: TableCell)
    func tableContentView(_ tableContentView: TableContentView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: TableCell)
    func tableContentView(_ tableContentView: TableContentView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: TableCell)
    func tableContentView(_ tableContentView: TableContentView, didChangeBounds bounds: CGRect, in cell: TableCell)

    func tableContentView(_ tableContentView: TableContentView, didSelectCells cells: [TableCell])
    func tableContentView(_ tableContentView: TableContentView, didUnselectCells cells: [TableCell])

    func tableContentView(_ tableContentView: TableContentView, didReceiveKey key: EditorKey, at range: NSRange, in cell: TableCell)

    func tableContentView(_ tableContentView: TableContentView, didAddNewRowAt index: Int)
    func tableContentView(_ tableContentView: TableContentView, didAddNewColumnAt index: Int)

    func tableContentView(_ tableContentView: TableContentView, didDeleteRowAt index: Int)
    func tableContentView(_ tableContentView: TableContentView, didDeleteColumnAt index: Int)

    func tableContentView(_ tableContentView: TableContentView, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool

    func tableContentView(_ tableContentView: TableContentView, cell: TableCell, didChangeBackgroundColor color: UIColor?, oldColor: UIColor?)

    func tableContentView(_ tableContentView: TableContentView, didUpdateCells cells: [TableCell])
}

class TableContentView: UIScrollView {
    private let table: Table
    private let config: GridConfiguration

    // Render with a high number for width/height to initialize
    // since Editor may not be (and most likely not initialized at init of GridView.
    // Having actual value causes autolayout errors in combination with fractional widths.
    private let initialSize = CGSize(width: 100, height: 100)
    private var frozenColumnsConstraints = [NSLayoutConstraint]()
    private var frozenRowsConstraints = [NSLayoutConstraint]()

    weak var tableContentViewDelegate: TableContentViewDelegate?
    weak var boundsObserver: BoundsObserving?

    var isFreeScrollingEnabled = false
    var isRendered = false

    var cells: [TableCell] {
        table.cells
    }

    private(set) var selectedCells: [TableCell] = [TableCell]()

    override var backgroundColor: UIColor? {
        didSet {
            cells.forEach { $0.updateBackgroundColorFromParent(color: backgroundColor, oldColor: oldValue) }
        }
    }

    var numberOfColumns: Int {
        table.numberOfColumns
    }

    var numberOfRows: Int {
        table.numberOfRows
    }

    var frozenRowMaxIndex: Int? {
        didSet {
            invalidateCellLayout()
        }
    }
    var frozenColumnMaxIndex: Int? {
        didSet {
            invalidateCellLayout()
        }
    }

    var columnWidths: [GridColumnDimension] {
        table.columnWidths
    }

    var widthAnchorConstraint: NSLayoutConstraint!
    var heightAnchorConstraint: NSLayoutConstraint!

    init(config: GridConfiguration, cells: [TableCell], editorInitializer: TableCell.EditorInitializer?) {
        self.config = config
        table = Table(config: config, cells: cells, editorInitializer: editorInitializer)
        super.init(frame: .zero)

//        self.widthAnchorConstraint = widthAnchor.constraint(lessThanOrEqualToConstant: 350)
        self.heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 100)
//        table.delegate = self
//
//        NSLayoutConstraint.activate([
//            widthAnchorConstraint,
//            heightAnchorConstraint
//        ])
    }

    convenience init(config: GridConfiguration, editorInitializer: TableCell.EditorInitializer?) {
        let cells = Self.generateCells(config: config, editorInitializer: editorInitializer)
        self.init(config: config, cells: cells, editorInitializer: editorInitializer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = table.sizeThatFits(size: frame.size)
        self.contentSize = size
        self.isScrollEnabled = size.width > frame.width
        self.alwaysBounceHorizontal = false
        return size
    }

    override var bounds: CGRect {
        didSet {
            guard oldValue.size != bounds.size else { return }
            recalculateCellBounds()
            tableContentViewDelegate?.tableContentView(self, didChangeBounds: bounds, oldBounds: oldValue)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableContentViewDelegate?.tableContentView(self, didCompleteLayoutWithBounds: bounds)
    }

    private func setup() {
        makeCells()
        setupSelectionGesture()
        tableContentViewDelegate?.tableContentView(self, didUpdateCells: cells)
    }

    public override func willMove(toWindow newWindow: UIWindow?) {
        guard isRendered == false,
              newWindow != nil else {
                  return
              }
        isRendered = true
        setup()
    }

    private func makeCells() {
        table.calculateTableDimensions(basedOn: bounds.size)
        for cell in cells {
            let frame = table.frameForCell(cell, basedOn: bounds.size)
            cell.frame = frame
            cell.delegate = self
        }
    }

    private func setupSelectionGesture() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSelection(_:)))
        gestureRecognizer.delegate = self
        gestureRecognizer.minimumNumberOfTouches = 2
        gestureRecognizer.maximumNumberOfTouches = 2
        addGestureRecognizer(gestureRecognizer)
    }

    func scrollTo(cell: TableCell, animated: Bool = true) {
        let frame = table.frameForCell(cell, basedOn: self.frame.size)
        self.scrollRectToVisible(frame, animated: animated)
    }

    func selectCells(_ cells: [TableCell]) {
        deselectCells()
//        selectedCells.append(contentsOf: cells)
        cells.first?.setFocus()
        cells.forEach { $0.isSelected = true }
    }

    func deselectCells() {
        selectedCells.forEach { $0.isSelected = false }
        selectedCells.removeAll()
    }

    func isMergeable(cells: [TableCell]) -> Bool {
        return table.isMergeable(cells: cells)
    }

    func merge(cells: [TableCell]) -> TableCell? {
        let mergedCell = table.merge(cells: cells)
        invalidateCellLayout()
        deselectCells()
        return mergedCell
    }

    func split(cell: TableCell) -> [TableCell] {
        let cells = table.split(cell: cell)
        invalidateCellLayout()
        // First cell is the existing merged cell. Others are added as new.
        deselectCells()
        return cells
    }

//    @discardableResult
//    func insertRow(at index: Int, configuration: GridRowConfiguration) -> Result<[TableCell], GridViewError> {
//        let result = grid.insertRow(at: index, frozenRowMaxIndex: frozenRowMaxIndex, config: configuration, cellDelegate: self)
//        if case Result.success = result {
//            invalidateCellLayout()
//            tableContentViewDelegate?.tableContentView(self, didAddNewRowAt: index)
//        }
//        return result
//    }
//
//    @discardableResult
//    func insertColumn(at index: Int, configuration: GridColumnConfiguration) -> Result<[TableCell], GridViewError> {
//        let result = grid.insertColumn(at: index, frozenColumnMaxIndex: frozenColumnMaxIndex, config: configuration, cellDelegate: self)
//        if case Result.success = result {
//            invalidateCellLayout()
//            tableContentViewDelegate?.tableContentView(self, didAddNewColumnAt: index)
//        }
//        return result
//    }

    func deleteRow(at index: Int) {
        table.deleteRow(at: index)
        invalidateCellLayout()
        tableContentViewDelegate?.tableContentView(self, didDeleteRowAt: index)
    }

    func deleteColumn(at index: Int) {
        table.deleteColumn(at: index)
        invalidateCellLayout()
        tableContentViewDelegate?.tableContentView(self, didAddNewColumnAt: index)
    }

    func collapseRow(at index: Int) {
        table.collapseRow(at: index)
        invalidateCellLayout()
    }

    func expandRow(at index: Int) {
        table.expandRow(at: index)
        invalidateCellLayout()
    }

    func collapseColumn(at index: Int) {
        table.collapseColumn(at: index)
        invalidateCellLayout()
    }

    func expandColumn(at index: Int) {
        table.expandColumn(at: index)
        invalidateCellLayout()
    }

    func getCollapsedRowIndices() -> [Int] {
        return table.getCollapsedRowIndices()
    }

    func getCollapsedColumnIndices() -> [Int] {
        return table.getCollapsedColumnIndices()
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> TableCell? {
        table.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    func changeColumnWidth(index: Int, delta: CGFloat) {
        table.changeColumnWidth(index: index, totalWidth: frame.width, delta: delta)
        invalidateCellLayout()
    }

    func changeRowHeight(index: Int, delta: CGFloat) {
        table.changeRowHeight(index: index, delta: delta)
        invalidateCellLayout()
    }

    @objc
    private func handleSelection(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self)
        if sender.state == .began {
            deselectCurrentSelection()
        }

        if sender.state == .began || sender.state == .changed {
            let cell = selectCellsInLocation(location)
            if sender.state == .began {
                cell?.setFocus()
            }
            let velocity = sender.velocity(in: self)
            let updatedOffset = contentOffset.x + (velocity.x/100)
            if updatedOffset >= 0, // prevent out of bounds scroll to left
               updatedOffset + bounds.width <= contentSize.width { // prevent out of bounds scroll to right
                contentOffset.x = updatedOffset
            }
        }
    }

    func selectCellsInLocation(_ location: CGPoint) -> TableCell? {
        guard let cell = cells.first(where: { $0.frame.contains(location) }) else { return nil }
        cell.isSelected = true
        return cell
    }

    func deselectCurrentSelection() {
        selectedCells.forEach { $0.isSelected = false }
        selectedCells.removeAll()
    }

    func invalidateCellLayout() {
        recalculateCellBounds()
    }

    private func recalculateCellBounds(cell: TableCell) {
        //TODO: Update frame for all affected cells and based on current cell
//        tableContentViewDelegate?.cellsInViewport.forEach{ cell in
//            let frame = table.frameForCell(cell, basedOn: bounds.size)
//            cell.frame = frame
//        }

        cells.forEach {
            $0.frame = table.frameForCell($0, basedOn: bounds.size)
        }

        self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: self.frame.width, height: table.size.height))

//        widthAnchorConstraint.constant = self.frame.width
        heightAnchorConstraint.constant = self.frame.height
        if heightAnchorConstraint.isActive == false {
            heightAnchorConstraint.isActive = true
        }

        contentSize = table.size
        superview?.layoutIfNeeded()
        boundsObserver?.didChangeBounds(CGRect(origin: bounds.origin, size: frame.size), oldBounds: bounds)
    }

    private func recalculateCellBounds(initiatingCell: TableCell? = nil) {
        //TODO: fix
//        frozenRowsConstraints.forEach { $0.isActive = false }
//        frozenColumnsConstraints.forEach { $0.isActive = false }
//        removeConstraints(frozenRowsConstraints + frozenColumnsConstraints)
//
//        var cells = table.cells
//        if let initiatingCell {
//            cells = [initiatingCell]
//        }
//
//        for cell in cells {
//            // TODO: Optimize to recalculate frames for affected cells only i.e. row>=current
//
//            // Set the frame of the cell before adding to superview
//            // This is required to avoid breaking layout constraints
//            // as default size is 0
//            let frame = table.frameForCell(cell, basedOn: bounds.size)
//            cell.frame = frame
//            cell.contentView.frame = frame
//            cell.widthAnchorConstraint.constant = frame.width
//            cell.heightAnchorConstraint.constant = frame.height
//
//            // Add to grid if this is a newly inserted cell after initial setup.
//            // A new cell may exist as a result of inserting a new row/column
//            // or splitting an existing merged cell
//            if cell.contentView.superview == nil {
//                addSubview(cell.contentView)
//                if window != nil, cell.editorSetupComplete == false {
//                    cell.setupEditor()
//                }
//                cell.topAnchorConstraint = cell.contentView.topAnchor.constraint(equalTo: topAnchor, constant: frame.minY)
//                cell.leadingAnchorConstraint = cell.contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: frame.minX)
//            } else {
//                cell.topAnchorConstraint?.constant = frame.minY
//                cell.leadingAnchorConstraint?.constant = frame.minX
//            }
//            freezeColumnCellIfRequired(cell)
//            freezeRowCellIfRequired(cell)
//            tableContentViewDelegate?.tableContentView(self, didLayoutCell: cell)
//        }
//
//        boundsObserver?.didChangeBounds(CGRect(origin: bounds.origin, size: frame.size), oldBounds: bounds)
//        invalidateIntrinsicContentSize()
    }

    private func freezeColumnCellIfRequired(_ cell: TableCell) {
        //TODO: fix
//        guard let minimumFrozenColumnIndex = frozenColumnMaxIndex,
//              let container = superview else { return }
//
//        if cell.columnSpan.contains(where: { $0 <= minimumFrozenColumnIndex }) {
//            bringSubviewToFront(cell.contentView)
//            cell.leadingAnchorConstraint.priority = .defaultLow
//            let minimumLeadingConstraint = cell.contentView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: cell.frame.minX)
//            NSLayoutConstraint.activate([
//                minimumLeadingConstraint
//            ])
//            frozenColumnsConstraints.append(minimumLeadingConstraint)
//        }
    }

    private func freezeRowCellIfRequired(_ cell: TableCell) {
    // TODO: fix
//        guard let minimumFrozenRowIndex = frozenRowMaxIndex,
//              let attachmentContentView = attachmentContentView,
//              let containerEditorView = attachmentContentView.attachment?.containerEditorView else { return }
//
//        if cell.rowSpan.contains(where: { $0 <= minimumFrozenRowIndex }) {
//            bringSubviewToFront(cell.contentView)
//            cell.topAnchorConstraint.priority = .defaultLow
//            let rowTopConstraint = cell.contentView.topAnchor.constraint(greaterThanOrEqualTo: containerEditorView.topAnchor, constant: cell.frame.minY)
//            let rowBottomConstraint = cell.contentView.bottomAnchor.constraint(lessThanOrEqualTo: attachmentContentView.bottomAnchor)
//            rowTopConstraint.priority = UILayoutPriority.defaultHigh
//            NSLayoutConstraint.activate([
//                rowTopConstraint,
//                rowBottomConstraint
//            ])
//            frozenRowsConstraints.append(contentsOf: [rowTopConstraint, rowBottomConstraint])
//        }
    }

    private static func generateCells(
        config: GridConfiguration,
        editorInitializer: TableCell.EditorInitializer?
    ) -> [TableCell] {
        var cells = [TableCell]()
        for row in 0..<config.numberOfRows {
            let rowStyle = config.rowsConfiguration[row].style
            let initialHeight = config.rowsConfiguration[row].initialHeight

            for column in 0..<config.numberOfColumns {
                let columnStyle = config.columnsConfiguration[column].style
                let mergedStyle = GridCellStyle.merged(style: rowStyle, other: columnStyle)
                let cell = TableCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    initialHeight: initialHeight,
                    style: mergedStyle,
                    gridStyle: config.style,
                    editorInitializer: editorInitializer
                )
                cells.append(cell)
            }
        }
        return cells
    }
}

extension TableContentView: TableCellDelegate {
    func cell(_ cell: TableCell, didAddContentView view: TableCellContentView) {
        addSubview(view)
    }

    func cell(_ cell: TableCell, didRemoveContentView view: TableCellContentView?) {
        view?.removeFromSuperview()
    }

    func cell(_ cell: TableCell, didReceiveFocusAt range: NSRange) {
        tableContentViewDelegate?.tableContentView(self, didReceiveFocusAt: range, in: cell)
    }

    func cell(_ cell: TableCell, didLoseFocusFrom range: NSRange) {
        tableContentViewDelegate?.tableContentView(self, didLoseFocusFrom: range, in: cell)
    }

    func cell(_ cell: TableCell, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        tableContentViewDelegate?.tableContentView(self, didTapAtLocation: location, characterRange: characterRange, in: cell)
    }

    func cell(_ cell: TableCell, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        tableContentViewDelegate?.tableContentView(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType, in: cell)
    }

    func cell(_ cell: TableCell, didChangeBackgroundColor color: UIColor?, oldColor: UIColor?) {
        tableContentViewDelegate?.tableContentView(self, cell: cell, didChangeBackgroundColor: color, oldColor: oldColor)
    }

    func cell(_ cell: TableCell, didChangeBounds bounds: CGRect) {
        guard  let row = cell.rowSpan.first else { return }
        if table.rowHeights.count > row,
           table.maxContentHeightCellForRow(at: row)?.id == cell.id {
            table.rowHeights[row].currentHeight = bounds.height
        } else {
            table.rowHeights[row].currentHeight = table.maxContentHeightCellForRow(at: row)?.contentSize.height ?? 0
        }
        //TODO: only update affected row/column onwards
        table.calculateTableDimensions(basedOn: bounds.size)
        recalculateCellBounds(cell: cell)
        tableContentViewDelegate?.tableContentView(self, didChangeBounds: cell.frame, in: cell)
    }

    func cell(_ cell: TableCell, didReceiveKey key: EditorKey, at range: NSRange) {
        if isLastCell(cell) {
            //TODO: fix
//            insertRow(at: grid.numberOfRows, configuration: GridRowConfiguration(initialHeight: 60))
        }
        tableContentViewDelegate?.tableContentView(self, didReceiveKey: key, at: range, in: cell)
    }

    func cell(_ cell: TableCell, didChangeSelected isSelected: Bool) {
        if isSelected == false {
            selectedCells.removeAll(where: { $0.id == cell.id })
        } else {
            selectedCells.append(cell)
        }
        tableContentViewDelegate?.tableContentView(self, didSelectCells: selectedCells)
    }

    private func isLastCell(_ cell: TableCell) -> Bool {
        return cell.columnSpan.contains(table.numberOfColumns - 1) && cell.rowSpan.contains(table.numberOfRows - 1)
    }
}

extension TableContentView: DynamicBoundsProviding {
    public func sizeFor(attachment: Attachment, containerSize: CGSize, lineRect: CGRect) -> CGSize {
        guard bounds.size != .zero else { return .zero }
        return table.sizeThatFits(size: frame.size)
    }
}

extension TableContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isFreeScrollingEnabled
    }
}

extension TableContentView: TableDelegate {
    var viewport: CGRect { bounds }

    func table(_ table: Table, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool {
        tableContentViewDelegate?.tableContentView(self, shouldChangeColumnWidth: proposedWidth, for: columnIndex) ?? true
    }
}

extension UIView {
    func drawBorder(width: CGFloat = 1, color: UIColor = .red) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
}
