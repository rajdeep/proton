//
//  GridContentView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 7/6/2022.
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

protocol GridContentViewDelegate: AnyObject {
    func gridContentView(_ gridContentView: GridContentView, didCompleteLayoutWithBounds bounds: CGRect)
    func gridContentView(_ gridContentView: GridContentView, didLayoutCell cell: GridCell)
    
    func gridContentView(_ gridContentView: GridContentView, didReceiveFocusAt range: NSRange, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didLoseFocusFrom range: NSRange, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didChangeBounds bounds: CGRect, in cell: GridCell)

    func gridContentView(_ gridContentView: GridContentView, didSelectCells cells: [GridCell])
    func gridContentView(_ gridContentView: GridContentView, didUnselectCells cells: [GridCell])

    func gridContentView(_ gridContentView: GridContentView, didReceiveKey key: EditorKey, at range: NSRange, in cell: GridCell)

    func gridContentView(_ gridContentView: GridContentView, didAddNewRowAt index: Int)
    func gridContentView(_ gridContentView: GridContentView, didAddNewColumnAt index: Int)

    func gridContentView(_ gridContentView: GridContentView, didDeleteRowAt index: Int)
    func gridContentView(_ gridContentView: GridContentView, didDeleteColumnAt index: Int)

    func gridContentView(_ gridContentView: GridContentView, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool
}

class GridContentView: UIScrollView {
    private let grid: Grid
    private let config: GridConfiguration

    // Render with a high number for width/height to initialize
    // since Editor may not be (and most likely not initialized at init of GridView.
    // Having actual value causes autolayout errors in combination with fractional widths.
    private let initialSize = CGSize(width: 100, height: 100)
    private var frozenColumnsConstraints = [NSLayoutConstraint]()
    private var frozenRowsConstraints = [NSLayoutConstraint]()

    weak var gridContentViewDelegate: GridContentViewDelegate?
    weak var boundsObserver: BoundsObserving?

    var isFreeScrollingEnabled = false
    var isRendered = false

    var cells: [GridCell] {
        grid.cells
    }

    var selectedCells: [GridCell] {
        cells.filter { $0.isSelected }
    }

    var numberOfColumns: Int {
        grid.numberOfColumns
    }

    var numberOfRows: Int {
        grid.numberOfRows
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
        grid.columnWidths
    }

    init(config: GridConfiguration, cells: [GridCell]) {
        self.config = config
        grid = Grid(config: config, cells: cells)
        super.init(frame: .zero)
        grid.delegate = self
    }

    convenience init(config: GridConfiguration) {
        let cells = Self.generateCells(config: config)
        self.init(config: config, cells: cells)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = grid.sizeThatFits(size: frame.size)
        self.contentSize = size
        self.isScrollEnabled = size.width > frame.width
        self.alwaysBounceHorizontal = false
        return size
    }

    override var bounds: CGRect {
        didSet {
            guard oldValue.size != bounds.size else { return }
            recalculateCellBounds()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gridContentViewDelegate?.gridContentView(self, didCompleteLayoutWithBounds: bounds)
    }

    private func setup() {
        makeCells()
        setupSelectionGesture()
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
        for cell in grid.cells {
            cell.setupEditor()
            cell.contentView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(cell.contentView)
            //TODO: revisit - likely issue with the layout margin guides ie non-zero padding
            let frame = grid.frameForCell(cell, basedOn: initialSize)
            cell.frame = frame
            let contentView = cell.contentView

            cell.widthAnchorConstraint.constant = frame.width
            cell.heightAnchorConstraint.constant = frame.height

            cell.topAnchorConstraint = contentView.topAnchor.constraint(equalTo: topAnchor, constant: frame.minY)
            cell.leadingAnchorConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: frame.minX)

            NSLayoutConstraint.activate([
                cell.topAnchorConstraint,
                cell.leadingAnchorConstraint,
                cell.widthAnchorConstraint,
                cell.heightAnchorConstraint
            ])

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

    func scrollTo(cell: GridCell, animated: Bool = true) {
        let frame = grid.frameForCell(cell, basedOn: self.frame.size)
        self.scrollRectToVisible(frame, animated: animated)
    }

    func isMergeable(cells: [GridCell]) -> Bool {
        return grid.isMergeable(cells: cells)
    }

    func merge(cells: [GridCell]) -> GridCell? {
        let mergedCell = grid.merge(cells: cells)
        invalidateCellLayout()
        return mergedCell
    }

    func split(cell: GridCell) -> [GridCell] {
        let cells = grid.split(cell: cell)
        invalidateCellLayout()
        return cells
    }

    func insertRow(at index: Int, configuration: GridRowConfiguration) -> Result<[GridCell], GridViewError> {
        let result = grid.insertRow(at: index, frozenRowMaxIndex: frozenRowMaxIndex, config: configuration, cellDelegate: self)
        if case Result.success = result {
            invalidateCellLayout()
            gridContentViewDelegate?.gridContentView(self, didAddNewRowAt: index)
        }
        return result
    }

    func insertColumn(at index: Int, configuration: GridColumnConfiguration) -> Result<[GridCell], GridViewError> {
        let result = grid.insertColumn(at: index, frozenColumnMaxIndex: frozenColumnMaxIndex, config: configuration, cellDelegate: self)
        if case Result.success = result {
            invalidateCellLayout()
            gridContentViewDelegate?.gridContentView(self, didAddNewColumnAt: index)
        }
        return result
    }

    func deleteRow(at index: Int) {
        grid.deleteRow(at: index)
        invalidateCellLayout()
        gridContentViewDelegate?.gridContentView(self, didDeleteRowAt: index)
    }

    func deleteColumn(at index: Int) {
        grid.deleteColumn(at: index)
        invalidateCellLayout()
        gridContentViewDelegate?.gridContentView(self, didAddNewColumnAt: index)
    }

    func collapseRow(at index: Int) {
        grid.collapseRow(at: index)
        invalidateCellLayout()
    }

    func expandRow(at index: Int) {
        grid.expandRow(at: index)
        invalidateCellLayout()
    }

    func collapseColumn(at index: Int) {
        grid.collapseColumn(at: index)
        invalidateCellLayout()
    }

    func expandColumn(at index: Int) {
        grid.expandColumn(at: index)
        invalidateCellLayout()
    }

    func getCollapsedRowIndices() -> [Int] {
        return grid.getCollapsedRowIndices()
    }

    func getCollapsedColumnIndices() -> [Int] {
        return grid.getCollapsedColumnIndices()
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> GridCell? {
        grid.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    func changeColumnWidth(index: Int, delta: CGFloat) {
        grid.changeColumnWidth(index: index, totalWidth: frame.width, delta: delta)
        invalidateCellLayout()
    }

    func changeRowHeight(index: Int, delta: CGFloat) {
        grid.changeRowHeight(index: index, delta: delta)
        invalidateCellLayout()
    }

    @objc
    private func handleSelection(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self)
        if sender.state == .began ||
            sender.state == .changed {
            selectCellsInLocation(location)
            let velocity = sender.velocity(in: self)
            contentOffset.x += (velocity.x/100)
        }
    }

    func selectCellsInLocation(_ location: CGPoint) {
        let cell = cells.first { $0.frame.contains(location) }
        cell?.isSelected = true
        gridContentViewDelegate?.gridContentView(self, didSelectCells: selectedCells)
    }

    func invalidateCellLayout() {
        recalculateCellBounds()
    }

    private func recalculateCellBounds(initiatingCell: GridCell? = nil) {
        frozenRowsConstraints.forEach { $0.isActive = false }
        frozenColumnsConstraints.forEach { $0.isActive = false }
        removeConstraints(frozenRowsConstraints + frozenColumnsConstraints)

        var cells = grid.cells
        if let initiatingCell {
            cells = [initiatingCell]
        }

        for cell in cells {
            // TODO: Optimize to recalculate frames for affected cells only i.e. row>=current

            // Set the frame of the cell before adding to superview
            // This is required to avoid breaking layout constraints
            // as default size is 0
            let frame = grid.frameForCell(cell, basedOn: bounds.size)
            cell.frame = frame
            cell.contentView.frame = frame
            cell.widthAnchorConstraint.constant = frame.width
            cell.heightAnchorConstraint.constant = frame.height

            // Add to grid if this is a newly inserted cell after initial setup.
            // A new cell may exist as a result of inserting a new row/column
            // or splitting an existing merged cell
            if cell.contentView.superview == nil {
                addSubview(cell.contentView)
                if window != nil, cell.editorSetupComplete == false {
                    cell.setupEditor()
                }
                cell.topAnchorConstraint = cell.contentView.topAnchor.constraint(equalTo: topAnchor, constant: frame.minY)
                cell.leadingAnchorConstraint = cell.contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: frame.minX)
            } else {
                cell.topAnchorConstraint?.constant = frame.minY
                cell.leadingAnchorConstraint?.constant = frame.minX
            }
            freezeColumnCellIfRequired(cell)
            freezeRowCellIfRequired(cell)
            gridContentViewDelegate?.gridContentView(self, didLayoutCell: cell)
        }

        boundsObserver?.didChangeBounds(CGRect(origin: bounds.origin, size: frame.size), oldBounds: bounds)
        invalidateIntrinsicContentSize()
    }

    private func freezeColumnCellIfRequired(_ cell: GridCell) {
        guard let minimumFrozenColumnIndex = frozenColumnMaxIndex,
              let container = superview else { return }

        if cell.columnSpan.contains(where: { $0 <= minimumFrozenColumnIndex }) {
            bringSubviewToFront(cell.contentView)
            cell.leadingAnchorConstraint.priority = .defaultLow
            let minimumLeadingConstraint = cell.contentView.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: cell.frame.minX)
            NSLayoutConstraint.activate([
                minimumLeadingConstraint
            ])
            frozenColumnsConstraints.append(minimumLeadingConstraint)
        }
    }

    private func freezeRowCellIfRequired(_ cell: GridCell) {
        guard let minimumFrozenRowIndex = frozenRowMaxIndex,
              let attachmentContentView = attachmentContentView,
              let containerEditorView = attachmentContentView.attachment?.containerEditorView else { return }

        if cell.rowSpan.contains(where: { $0 <= minimumFrozenRowIndex }) {
            bringSubviewToFront(cell.contentView)
            cell.topAnchorConstraint.priority = .defaultLow
            let rowTopConstraint = cell.contentView.topAnchor.constraint(greaterThanOrEqualTo: containerEditorView.topAnchor, constant: cell.frame.minY)
            let rowBottomConstraint = cell.contentView.bottomAnchor.constraint(lessThanOrEqualTo: attachmentContentView.bottomAnchor)
            rowTopConstraint.priority = UILayoutPriority.defaultHigh
            NSLayoutConstraint.activate([
                rowTopConstraint,
                rowBottomConstraint
            ])
            frozenRowsConstraints.append(contentsOf: [rowTopConstraint, rowBottomConstraint])
        }
    }

    private static func generateCells(config: GridConfiguration) -> [GridCell] {
        var cells = [GridCell]()
        for row in 0..<config.numberOfRows {
            let rowStyle = config.rowsConfiguration[row].style
            let initialHeight = config.rowsConfiguration[row].initialHeight

            for column in 0..<config.numberOfColumns {
                let columnStyle = config.columnsConfiguration[column].style
                let mergedStyle = GridCellStyle.merged(style: rowStyle, other: columnStyle)
                let cell = GridCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    initialHeight: initialHeight,
                    style: mergedStyle,
                    gridStyle: config.style,
                    ignoresOptimizedInit: config.ignoresOptimizedInit
                )
                cells.append(cell)
            }
        }
        return cells
    }
}

extension GridContentView: GridCellDelegate {
    func cell(_ cell: GridCell, didReceiveFocusAt range: NSRange) {
        gridContentViewDelegate?.gridContentView(self, didReceiveFocusAt: range, in: cell)
    }

    func cell(_ cell: GridCell, didLoseFocusFrom range: NSRange) {
        gridContentViewDelegate?.gridContentView(self, didLoseFocusFrom: range, in: cell)
    }

    func cell(_ cell: GridCell, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        gridContentViewDelegate?.gridContentView(self, didTapAtLocation: location, characterRange: characterRange, in: cell)
    }

    func cell(_ cell: GridCell, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        gridContentViewDelegate?.gridContentView(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType, in: cell)
    }

    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect) {
        guard  let row = cell.rowSpan.first else { return }
        if grid.rowHeights.count > row,
           grid.maxContentHeightCellForRow(at: row)?.id == cell.id {
            grid.rowHeights[row].currentHeight = bounds.height
        } else {
            grid.rowHeights[row].currentHeight = grid.maxContentHeightCellForRow(at: row)?.contentSize.height ?? 0
        }

        recalculateCellBounds(initiatingCell: cell)
        gridContentViewDelegate?.gridContentView(self, didChangeBounds: cell.frame, in: cell)
    }

    func cell(_ cell: GridCell, didReceiveKey key: EditorKey, at range: NSRange) {
        if isLastCell(cell) {
            insertRow(at: grid.numberOfRows, configuration: GridRowConfiguration(initialHeight: 60))
        }
        gridContentViewDelegate?.gridContentView(self, didReceiveKey: key, at: range, in: cell)
    }

    private func isLastCell(_ cell: GridCell) -> Bool {
        return cell.columnSpan.contains(grid.numberOfColumns - 1) && cell.rowSpan.contains(grid.numberOfRows - 1)
    }
}

extension GridContentView: DynamicBoundsProviding {
    public func sizeFor(attachment: Attachment, containerSize: CGSize, lineRect: CGRect) -> CGSize {
        guard bounds.size != .zero else { return .zero }
        return grid.sizeThatFits(size: frame.size)
    }
}

extension GridContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return isFreeScrollingEnabled
    }
}

extension GridContentView: GridDelegate {
    func grid(_ grid: Grid, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool {
        gridContentViewDelegate?.gridContentView(self, shouldChangeColumnWidth: proposedWidth, for: columnIndex) ?? true
    }
}
