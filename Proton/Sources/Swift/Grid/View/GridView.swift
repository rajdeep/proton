//
//  GridView.swift
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
import UIKit

/// An object capable of handing `GridView` events
public protocol GridViewDelegate: AnyObject {
    func gridView(_ gridView: GridView, didReceiveFocusAt range: NSRange, in cell: GridCell)
    func gridView(_ gridView: GridView, didLoseFocusFrom range: NSRange, in cell: GridCell)
    func gridView(_ gridView: GridView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell)
    func gridView(_ gridView: GridView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell)
    func gridView(_ gridView: GridView, didChangeBounds bounds: CGRect, in cell: GridCell)
    func gridView(_ gridView: GridView, didSelectCells cells: [GridCell])
    func gridView(_ gridView: GridView, didUnselectCells cells: [GridCell])
    func gridView(_ gridView: GridView, didReceiveKey key: EditorKey, at range: NSRange, in cell: GridCell)
}

/// A view that provides a tabular structure where each cell is an `EditorView`.
/// Since the cells contains an `EditorView` in itself, it is capable of hosting any attachment that `EditorView` can host
/// including another `GridView` as an attachment.
public class GridView: UIView {
    private let gridView: GridContentView
    private var columnResizingHandles = [CellHandleButton]()
    private let handleSize: CGFloat = 20
    private let config: GridConfiguration
    private let selectionView = SelectionView()
    private var resizingDragHandleLastLocation: CGPoint? = nil

    private lazy var columnRightBorderView: UIView = {
        makeSelectionBorderView()
    }()

    private lazy var columnLeftBorderView: UIView = {
        makeSelectionBorderView()
    }()

    private lazy var columnTopBorderView: UIView = {
        makeSelectionBorderView()
    }()

    private lazy var columnBottomBorderView: UIView = {
        makeSelectionBorderView()
    }()

    /// Delegate for `GridView` which can be used to handle cell specific `EditorView` events
    public weak var delegate: GridViewDelegate?

    /// Determines if column resizing handles are visible or not.
    public private(set) var isColumnResizingHandlesVisible = false {
        didSet {
            if isColumnResizingHandlesVisible == false {
                removeColumnResizingHandles()
            }
        }
    }

    /// Bounds observer for the `GridView`. Typically, this will be the `Attachment` that hosts the `GridView`.
    /// - Note: In absence of a `boundObserver`, the `GridView` will not autoresize when the content in the cells
    /// are changed.
    public var boundsObserver: BoundsObserving? {
        get { gridView.boundsObserver }
        set { gridView.boundsObserver = newValue }
    }

    /// Selection color for the `GridView`. Defaults to `tintColor`
    public var selectionColor: UIColor?

    /// Determines if `GridView` is selected or not.
    public var isSelected: Bool = false {
        didSet {
            if isSelected {
                selectionView.addTo(parent: self, selectionColor: selectionColor)
            } else {
                selectionView.removeFromSuperview()
            }
        }
    }

    /// Collection of cells contained in the `GridView`
    public var cells: [GridCell] {
        gridView.cells
    }

    // Collection of cells currently selected in the `GridView`
    public var selectedCells: [GridCell] {
        gridView.selectedCells
    }

    /// Number of columns in the `GridView`.
    public var numberOfColumns: Int {
        gridView.numberOfColumns
    }

    /// Number of rows in the `GridView`
    public var numberOfRows: Int {
        gridView.numberOfRows
    }


    /// Initializes `GridView` using the provided configuration.
    /// - Parameter config: Configuration for `GridView`
    public init(config: GridConfiguration) {
        self.gridView = GridContentView(config: config)
        self.config = config
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.gridContentViewDelegate = self
        addSubview(gridView)
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: topAnchor),
            gridView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func makeSelectionBorderView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = tintColor
        view.alpha = 0.4
        return view
    }

    private func addColumnResizingHandles(selectedCell: GridCell) {
        guard isColumnResizingHandlesVisible else { return }

        for cell in cells where cell.columnSpan.max() == selectedCell.columnSpan.max() {
            let handleView = makeColumnResizingHandle(cell: cell)
            columnResizingHandles.append(handleView)
            handleView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(handleView)
            NSLayoutConstraint.activate([
                handleView.widthAnchor.constraint(equalToConstant: handleSize),
                handleView.heightAnchor.constraint(equalTo: handleView.widthAnchor),
                handleView.centerYAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                handleView.centerXAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ])
        }

        addSelectionBorders(grid: self, cell: selectedCell)
    }

    private func addSelectionBorders(grid: GridView, cell: GridCell) {
        addSubview(columnRightBorderView)
        addSubview(columnLeftBorderView)
        addSubview(columnTopBorderView)
        addSubview(columnBottomBorderView)

        NSLayoutConstraint.activate([
            columnRightBorderView.centerXAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            columnRightBorderView.widthAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
            columnRightBorderView.heightAnchor.constraint(equalTo: gridView.heightAnchor),
            columnRightBorderView.topAnchor.constraint(equalTo: gridView.topAnchor),

            columnLeftBorderView.centerXAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            columnLeftBorderView.widthAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
            columnLeftBorderView.heightAnchor.constraint(equalTo: gridView.heightAnchor),
            columnLeftBorderView.topAnchor.constraint(equalTo: gridView.topAnchor),

            columnTopBorderView.centerYAnchor.constraint(equalTo: gridView.topAnchor),
            columnTopBorderView.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor),
            columnTopBorderView.heightAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
            columnTopBorderView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),

            columnBottomBorderView.centerYAnchor.constraint(equalTo: gridView.bottomAnchor),
            columnBottomBorderView.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor),
            columnBottomBorderView.heightAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
            columnBottomBorderView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),

        ])
    }

    private func removeColumnResizingHandles() {
        columnResizingHandles.forEach { $0.removeFromSuperview() }
        columnResizingHandles.removeAll()
        removeSelectionBorders()
    }

    private func removeSelectionBorders() {
        columnRightBorderView.removeFromSuperview()
        columnLeftBorderView.removeFromSuperview()
        columnTopBorderView.removeFromSuperview()
        columnBottomBorderView.removeFromSuperview()
    }

    private func resetColumnResizingHandles(selectedCell: GridCell) {
        removeColumnResizingHandles()
        addColumnResizingHandles(selectedCell: selectedCell)
    }

    private func makeColumnResizingHandle(cell: GridCell) -> CellHandleButton {
        let dragHandle = CellHandleButton(cell: cell, cornerRadius: handleSize/2)
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dragHandler(gesture:))))
        return dragHandle
    }

    @objc
    private func dragHandler(gesture: UIPanGestureRecognizer){
        guard let draggedView = gesture.view,
              let cell = (draggedView as? CellHandleButton)?.cell else { return }

        let location = gesture.location(in: self)
        if gesture.state == .changed {
            if let lastLocation = resizingDragHandleLastLocation {
                let deltaX = location.x - lastLocation.x
                gridView.changeColumnWidth(index: cell.columnSpan.max() ?? 0, delta: deltaX)
            }
            resizingDragHandleLastLocation = location
        }

        if gesture.state == .ended
            || gesture.state == .cancelled
            || gesture.state == .ended {
            resizingDragHandleLastLocation = nil
        }
    }

    /// Enables display of resizing handle for columns
    public func showsColumnResizingHandles() {
        isColumnResizingHandlesVisible = true
    }

    /// Disables display of resizing handles for columns
    public func hideCellResizingHandles() {
        isColumnResizingHandlesVisible = false
    }


    /// Determines if the collection of cells can be merged. For cells to be mergable, they need to
    /// be adjacent to each other, and the shape of selection needs to be rectangular.
    /// - Parameter cells: Collection of cells to check if these can be merged.
    /// - Returns: `true` is cells can be merged.
    public func isCellSelectionMergeable(_ cells: [GridCell]) -> Bool {
        gridView.isMergeable(cells: cells)
    }

    /// Merges the cells if the collection is mergeable.
    /// - Parameter cells: Cells to merge.
    public func merge(cells: [GridCell]) {
        if let mergedCell = gridView.merge(cells: cells) {
            resetColumnResizingHandles(selectedCell: mergedCell)
        }
    }

    /// Splits the cell into original constituent cells from earlier Merge operation.
    /// After split, the contents are held in the first original cell and all new split cells
    /// are added as empty,
    /// - Parameter cell: Cell to split.
    public func split(cell: GridCell) {
        let cells = gridView.split(cell: cell)
        if let cell = cells.last {
            resetColumnResizingHandles(selectedCell: cell)
        }
    }

    /// Inserts a new row at given index.
    /// - Parameters:
    ///   - index: Index at which new row should be inserted.
    ///     If the index is out of bounds, row will be inserted at the top or bottom of the grid based on index value
    ///   - configuration: Configuration for the new row
    public func insertRow(at index: Int, configuration: GridRowConfiguration) {
        gridView.insertRow(at: index, configuration: configuration)
    }

    /// Inserts a new column at given index.
    /// - Parameters:
    ///   - index: Index at which new column should be inserted.
    ///   If the index is out of bounds, column will be inserted at the beginning or end of the grid based on index value
    ///   - configuration: Configuration for the new column
    public func insertColumn(at index: Int, configuration: GridColumnConfiguration) {
        gridView.insertColumn(at: index, configuration: configuration)
    }

    /// Deletes the row at given index
    /// - Parameter index: Index to delete
    public func deleteRow(at index: Int) {
        gridView.deleteRow(at: index)
    }

    /// Deletes the column at given index
    /// - Parameter index: Index to delete
    public func deleteColumn(at index: Int) {
        gridView.deleteColumn(at: index)
    }

    /// Gets the cell at given row and column index. Indexes may be contained in a merged cell.
    /// - Parameters:
    ///   - rowIndex: Row index for the cell
    ///   - columnIndex: Column index for the cell
    /// - Returns: Cell at given row and column, if exists`
    public func cellAt(rowIndex: Int, columnIndex: Int) -> GridCell? {
        return gridView.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    /// Scrolls the cell at given index into viewable area. Indexes may be contained in a merged cell.
    /// - Parameters:
    ///   - rowIndex: Row index of the cell
    ///   - columnIndex: Column index for the cell
    ///   - animated: Animates scroll if `true`
    public func scrollToCellAt(rowIndex: Int, columnIndex: Int, animated: Bool = true) {
        if let cell = cellAt(rowIndex: rowIndex, columnIndex: columnIndex) {
            gridView.scrollTo(cell: cell, animated: animated)
        }
    }
}

extension GridView: GridContentViewDelegate {
    func gridContentView(_ gridContentView: GridContentView, didSelectCells cells: [GridCell]) {
        delegate?.gridView(self, didSelectCells: cells)
    }

    func gridContentView(_ gridContentView: GridContentView, didUnselectCells cells: [GridCell]) {
        delegate?.gridView(self, didUnselectCells: cells)
    }

    func gridContentView(_ gridContentView: GridContentView, didReceiveFocusAt range: NSRange, in cell: GridCell) {
        resetColumnResizingHandles(selectedCell: cell)
        delegate?.gridView(self, didReceiveFocusAt: range, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didLoseFocusFrom range: NSRange, in cell: GridCell) {
        removeSelectionBorders()
        delegate?.gridView(self, didLoseFocusFrom: range, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell) {
        delegate?.gridView(self, didTapAtLocation: location, characterRange: characterRange, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell) {
        delegate?.gridView(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didChangeBounds bounds: CGRect, in cell: GridCell) {
        delegate?.gridView(self, didChangeBounds: bounds, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didReceiveKey key: EditorKey, at range: NSRange, in cell: GridCell) {
        delegate?.gridView(self, didReceiveKey: key, at: range, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didAddNewRowAt index: Int) {
        if let cell = gridView.cellAt(rowIndex: index, columnIndex: 0) {
            cell.setFocus()
            gridView.scrollTo(cell: cell)
        }
    }

    func gridContentView(_ gridContentView: GridContentView, didAddNewColumnAt index: Int) {
        if let cell = gridView.cellAt(rowIndex: 0, columnIndex: index) {
            cell.setFocus()
            gridView.scrollTo(cell: cell)
        }
    }

    func gridContentView(_ gridContentView: GridContentView, didDeleteRowAt index: Int) {
    }

    func gridContentView(_ gridContentView: GridContentView, didDeleteColumnAt index: Int) {
    }
}

class CellHandleButton: UIButton {
    let cell: GridCell

    init(cell: GridCell, cornerRadius: CGFloat) {
        self.cell = cell
        super.init(frame: .zero)
        layer.cornerRadius = cornerRadius
        alpha = 0.4
        backgroundColor = tintColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
