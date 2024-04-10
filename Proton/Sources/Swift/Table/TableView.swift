//
//  TableView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/4/2024.
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

/// An object capable of handing `TableView` events
public protocol TableViewDelegate: AnyObject {
    var containerScrollView: UIScrollView? { get }

    var viewport: CGRect? { get }

    /// Invoked when `EditorView` within the cell receives focus
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - range: Range of content in the `EditorView` within the Cell
    ///   - cell: Cell containing Editor
    func tableView(_ tableView: TableView, didReceiveFocusAt range: NSRange, in cell: TableCell)

    /// Invoked when `EditorView` within the cell loses focus
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - range: Range of content in the `EditorView` within the Cell
    ///   - cell: Cell containing Editor
    func tableView(_ tableView: TableView, didLoseFocusFrom range: NSRange, in cell: TableCell)

    /// Invoked when tap event occurs within the Editor contained in the cell.
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - location: Tapped location
    ///   - characterRange: Range of characters in the Editor at the tapped location
    ///   - cell: Cell containing Editor
    func tableView(_ tableView: TableView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: TableCell)

    /// Invoked on selection changes with in the Editor contained in the cell.
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - range: Range of selection in the `EditorView` within the Cell
    ///   - attributes: Attributes at selected range
    ///   - contentType: `ContentType` at selected range
    ///   - cell: Cell containing Editor
    func tableView(_ tableView: TableView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: TableCell)

    /// Invoked on change of bounds of the Editor within the cell
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - bounds: Bounds of the EditorView within the cell. Height of EditorView may be less than that of the Cell.
    ///   - cell: Cell containing Editor
    func tableView(_ tableView: TableView, didChangeBounds bounds: CGRect, in cell: TableCell)

    /// Invoked when selection of cells is changed.
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - cells: Selected cells
    func tableView(_ tableView: TableView, didSelectCells cells: [TableCell])


    /// Invoked when selection of cells is changed.
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - cells: Cells that are changed from selected to unselected.
    func tableView(_ tableView: TableView, didUnselectCells cells: [TableCell])

    /// Invoked when special keys are intercepted in the Editor contained in the cell.
    /// - Parameters:
    ///   - tableView: TableView containing cell
    ///   - key: Special key
    ///   - range: Range at with the key is intercepted.
    ///   - cell: Cell containing Editor
    func tableView(_ tableView: TableView, didReceiveKey key: EditorKey, at range: NSRange, in cell: TableCell)

    /// Invoked when a column in `TableView` is resized.
    /// - Parameters:
    ///   - tableView: TableView containing column
    ///   - proposedWidth: Proposed column width before the change
    ///   - columnIndex: Index of column being resized
    /// - Returns: `true` if column resizing should be allowed, else false.
    func tableView(_ tableView: TableView, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool

    /// Notifies when `TableView` lays out a cell. This is called after the bounds calculation for the cell have been performed.
    /// Rendering of cell may not have been completed at this time.
    /// - Parameters:
    ///   - tableView: TableView containing the cell.
    ///   - cell: Cell being laid out
    func tableView(_ tableView: TableView, didLayoutCell cell: TableCell)
}

/// A view that provides a tabular structure where each cell is an `EditorView`.
/// Since the cells contains an `EditorView` in itself, it is capable of hosting any attachment that `EditorView` can host
/// including another `TableView` as an attachment.
public class TableView: UIView {
    let tableView: TableContentView
    private let leadingShadowView: UIView
    private let trailingShadowView: UIView
    private var columnResizingHandles = [TableCellHandleButton]()
    private let handleSize: CGFloat = 20
    private let config: GridConfiguration
    private let selectionView = SelectionView()
    private var resizingDragHandleLastLocation: CGPoint? = nil
    private var leadingShadowConstraint: NSLayoutConstraint!

    private var observation: NSKeyValueObservation?

    private let repository = TableCellRepository()

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

    private var shadowWidth: CGFloat {
        10.0
    }

    /// Delegate for `TableView` which can be used to handle cell specific `EditorView` events
    public weak var delegate: TableViewDelegate? {
        didSet {
            (delegate != nil) ? setupScrollObserver() : removeScrollObserver()
        }
    }

    /// Gets the attachment containing the `TableView`
    public var containerAttachment: Attachment? {
        attachmentContentView?.attachment
    }

    /// Determines if column resizing handles are visible or not.
    public private(set) var isColumnResizingHandlesVisible = false {
        didSet {
            if isColumnResizingHandlesVisible == false {
                removeColumnResizingHandles()
            }
        }
    }

    /// Bounds observer for the `TableView`. Typically, this will be the `Attachment` that hosts the `TableView`.
    /// - Note: In absence of a `boundObserver`, the `TableView` will not autoresize when the content in the cells
    /// are changed.
    public var boundsObserver: BoundsObserving? {
        get { tableView.boundsObserver }
        set { tableView.boundsObserver = newValue }
    }

    /// Selection color for the `TableView`. Defaults to `tintColor`
    public var selectionColor: UIColor?

    /// Determines if `TableView` is selected or not.
    public var isSelected: Bool = false {
        didSet {
            if isSelected {
                selectionView.addTo(parent: self, selectionColor: selectionColor)
            } else {
                selectionView.removeFromSuperview()
            }
        }
    }

    /// Allows scrolling grid in any direction. Defaults to `false`
    /// Default behaviour restricts scrolling to horizontal or vertical direction at a time.
    public var isFreeScrollingEnabled: Bool {
        get { tableView.isFreeScrollingEnabled }
        set { tableView.isFreeScrollingEnabled  = newValue }
    }

    /// Maximum index up till which columns are frozen. Columns are frozen from 0 to this index value.
    public var frozenColumnMaxIndex: Int? {
        return tableView.frozenColumnMaxIndex
    }

    /// Maximum index up till which rows are frozen. Rows are frozen from 0 to this index value.
    public var frozenRowMaxIndex: Int? {
        return tableView.frozenRowMaxIndex
    }

    ///  Determines if there are any frozen columns in the `TableView`
    public var containsFrozenColumns: Bool {
        tableView.frozenColumnMaxIndex != nil
    }

    ///  Determines if there are any frozen rows in the `TableView`
    public var containsFrozenRows: Bool {
        tableView.frozenRowMaxIndex != nil
    }

    /// Collection of cells contained in the `TableView`
    public var cells: [TableCell] {
        tableView.cells
    }

    // Collection of cells currently selected in the `TableView`
    public var selectedCells: [TableCell] {
        tableView.selectedCells
    }

    /// Number of columns in the `TableView`.
    public var numberOfColumns: Int {
        tableView.numberOfColumns
    }

    /// Number of rows in the `TableView`
    public var numberOfRows: Int {
        tableView.numberOfRows
    }

    /// Initializes `TableView` using the provided configuration.
    /// - Parameter
    ///   - config: Configuration for `TableView`
    ///   - cellEditorInitializer: Custom initializer for `EditorView` within `TableCell`. This will also be used when creating new cells as a
    ///   return of adding new row or column, or cells being split.
    public convenience init(config: GridConfiguration, cellEditorInitializer: GridCell.EditorInitializer? = nil) {
        let tableView = TableContentView(config: config, editorInitializer: cellEditorInitializer)
        self.init(config: config, tableView: tableView)
    }

    /// Initializes `TableView` using the provided configuration.
    /// - Parameters:
    ///   - config: Configuration for `TableView`
    ///   - cells: Cells contained within `TableView`
    ///   - cellEditorInitializer: Custom initializer for `EditorView` within `TableCell`. This will also be used when creating new cells as a
    ///   return of adding new row or column, or cells being split.
    ///   - Important:
    ///   Care must be taken that the number of cells are correct per the configuration provided, failing which the `TableView` rendering may be broken.
    public convenience init(config: GridConfiguration, cells: [TableCell], cellEditorInitializer: TableCell.EditorInitializer? = nil) {
        let tableView = TableContentView(config: config, cells: cells, editorInitializer: cellEditorInitializer)
        self.init(config: config, tableView: tableView)
    }

    private init(config: GridConfiguration, tableView: TableContentView) {
        self.tableView = tableView
        let boundsShadowColors = [
            config.boundsLimitShadowColors.primary.cgColor,
            config.boundsLimitShadowColors.secondary.cgColor
        ]
        self.leadingShadowView = GradientView(colors: boundsShadowColors)
        self.leadingShadowView.alpha = 0.2
        self.trailingShadowView = GradientView(colors: boundsShadowColors.reversed())
        self.trailingShadowView.alpha = 0.2
        self.config = config
        super.init(frame: .zero)
        self.leadingShadowConstraint = leadingShadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var backgroundColor: UIColor? {
        didSet {
            tableView.backgroundColor = backgroundColor
        }
    }

    private func setup() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        leadingShadowView.translatesAutoresizingMaskIntoConstraints = false
        trailingShadowView.translatesAutoresizingMaskIntoConstraints = false

        tableView.tableContentViewDelegate = self
        tableView.delegate = self

        addSubview(tableView)
        addSubview(leadingShadowView)
        addSubview(trailingShadowView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),

            leadingShadowView.widthAnchor.constraint(equalToConstant: shadowWidth),
            leadingShadowConstraint,
            leadingShadowView.topAnchor.constraint(equalTo: topAnchor),
            leadingShadowView.bottomAnchor.constraint(equalTo: bottomAnchor),

            trailingShadowView.widthAnchor.constraint(equalToConstant: shadowWidth),
            trailingShadowView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trailingShadowView.topAnchor.constraint(equalTo: topAnchor),
            trailingShadowView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupScrollObserver() {
        observation = delegate?.containerScrollView?.observe(\.bounds, options: [.new, .old]) { [weak self] container, change in
            self?.viewportChanged()
        }
    }

    private func removeScrollObserver() {
        observation?.invalidate()
    }

    deinit {
        removeScrollObserver()
    }

    var cellsInViewport: [TableCell] = [] {
        didSet {
            guard oldValue != cellsInViewport else { return }

            let oldCells = Set(oldValue)
            let newCells = Set(cellsInViewport)
            let toGenerate = newCells.subtracting(oldCells)
            let toReclaim = oldCells.subtracting(newCells)

            toReclaim.forEach { [weak self] in
                self?.repository.enqueue(cell: $0)
            }

            toGenerate.forEach { [weak self] in
                self?.repository.dequeue(for: $0)
            }
        }
    }

    private func viewportChanged() {
        guard self.bounds != .zero,
              let container = delegate?.containerScrollView else { return }
        let containerViewport = delegate?.viewport ?? container.bounds
        let tableViewport = tableView.bounds

        let x = max(tableViewport.minX, containerViewport.minX)
        let y = max(tableViewport.minY, containerViewport.minY)

        let width = min(tableViewport.width, containerViewport.width)
        let height = min(tableViewport.height, containerViewport.height)

        let viewport = CGRect(x: x, y: y, width: width, height: height)

        cellsInViewport = tableView.cells.filter{ $0.frame != .zero && $0.frame.intersects(viewport) }
    }

    private func makeSelectionBorderView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = tintColor
        view.alpha = 0.4
        return view
    }

    private func addColumnResizingHandles(selectedCell: TableCell) {
        guard isColumnResizingHandlesVisible else { return }

//        for cell in cells where cell.columnSpan.max() == selectedCell.columnSpan.max() {
//            let handleView = makeColumnResizingHandle(cell: cell)
//            columnResizingHandles.append(handleView)
//            handleView.translatesAutoresizingMaskIntoConstraints = false
//            addSubview(handleView)
//            NSLayoutConstraint.activate([
//                handleView.widthAnchor.constraint(equalToConstant: handleSize),
//                handleView.heightAnchor.constraint(equalTo: handleView.widthAnchor),
//                handleView.centerYAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
//                handleView.centerXAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
//            ])
//        }

        addSelectionBorders(grid: self, cell: selectedCell)
    }

    private func addSelectionBorders(grid: TableView, cell: TableCell) {
        addSubview(columnRightBorderView)
        addSubview(columnLeftBorderView)
        addSubview(columnTopBorderView)
        addSubview(columnBottomBorderView)

//        NSLayoutConstraint.activate([
//            columnRightBorderView.centerXAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
//            columnRightBorderView.widthAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
//            columnRightBorderView.heightAnchor.constraint(equalTo: tableView.heightAnchor),
//            columnRightBorderView.topAnchor.constraint(equalTo: tableView.topAnchor),
//
//            columnLeftBorderView.centerXAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
//            columnLeftBorderView.widthAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
//            columnLeftBorderView.heightAnchor.constraint(equalTo: tableView.heightAnchor),
//            columnLeftBorderView.topAnchor.constraint(equalTo: tableView.topAnchor),
//
//            columnTopBorderView.centerYAnchor.constraint(equalTo: tableView.topAnchor),
//            columnTopBorderView.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor),
//            columnTopBorderView.heightAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
//            columnTopBorderView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
//
//            columnBottomBorderView.centerYAnchor.constraint(equalTo: tableView.bottomAnchor),
//            columnBottomBorderView.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor),
//            columnBottomBorderView.heightAnchor.constraint(equalToConstant: cell.gridStyle.borderWidth * 2),
//            columnBottomBorderView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
//
//        ])
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

    private func resetColumnResizingHandles(selectedCell: TableCell) {
        removeColumnResizingHandles()
        addColumnResizingHandles(selectedCell: selectedCell)
    }

    private func makeColumnResizingHandle(cell: TableCell) -> TableCellHandleButton {
        let dragHandle = TableCellHandleButton(cell: cell, cornerRadius: handleSize/2)
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
                tableView.changeColumnWidth(index: cell.columnSpan.max() ?? 0, delta: deltaX)
            }
            resizingDragHandleLastLocation = location
        }

        if gesture.state == .ended
            || gesture.state == .cancelled
            || gesture.state == .ended {
            resizingDragHandleLastLocation = nil
        }
    }

    /// Enables or disables column resizing
    /// - Parameter enabled: `true` to enable resizing
    public func setColumnResizing(_ enabled: Bool) {
        isColumnResizingHandlesVisible = enabled
    }

    /// Gets the cell for the `EditorView` contained in the current instance
    /// - Parameter editor: Editor for which cell needs to be queried.
    /// - Returns: `TableCell` that contains the passed in `EditorView`, if present
    public func cellFor(_ editor: EditorView) -> TableCell? {
        return cells.first(where: { $0.contentView?.editor == editor })
    }

    /// Selects given cells. Also, deselects any previously selected cells
    /// - Parameter cells: Cells to select.
    /// - Note:
    /// Any combination of cells can be passed in, and will be selected, if possible.
    public func selectCells(_ cells: [TableCell]) {
        tableView.selectCells(cells)
    }

    /// Deselects any selected cell.
    public func deselectCells() {
        tableView.deselectCells()
    }

    /// Determines if the collection of cells can be merged. For cells to be mergable, they need to
    /// be adjacent to each other, and the shape of selection needs to be rectangular.
    /// - Parameter cells: Collection of cells to check if these can be merged.
    /// - Returns: `true` is cells can be merged.
    public func isCellSelectionMergeable(_ cells: [TableCell]) -> Bool {
        tableView.isMergeable(cells: cells)
    }

    /// Merges the cells if the collection is mergeable.
    /// - Parameter cells: Cells to merge.
    public func merge(cells: [TableCell]) {
        if let mergedCell = tableView.merge(cells: cells) {
            resetColumnResizingHandles(selectedCell: mergedCell)
        }
    }

    /// Splits the cell into original constituent cells from earlier Merge operation.
    /// After split, the contents are held in the first original cell and all new split cells
    /// are added as empty,
    /// - Parameter cell: Cell to split.
    public func split(cell: TableCell) {
        let cells = tableView.split(cell: cell)
        if let cell = cells.last {
            resetColumnResizingHandles(selectedCell: cell)
        }
    }

    /// Inserts a new row at given index.
    /// - Parameters:
    ///   - index: Index at which new row should be inserted.
    ///     If the index is out of bounds, row will be inserted at the top or bottom of the grid based on index value
    ///   - configuration: Configuration for the new row
    /// - Returns: Result with newly added cells for `.success`, error in case of `.failure`
//    @discardableResult
//    public func insertRow(at index: Int, configuration: GridRowConfiguration) -> Result<[TableCell], TableViewError> {
//        tableView.insertRow(at: index, configuration: configuration)
//    }

    /// Inserts a new column at given index.
    /// - Parameters:
    ///   - index: Index at which new column should be inserted.
    ///   If the index is out of bounds, column will be inserted at the beginning or end of the grid based on index value
    ///   - configuration: Configuration for the new column
    /// - Returns: Result with newly added cells for `.success`, error in case of `.failure`
//    @discardableResult
//    public func insertColumn(at index: Int, configuration: GridColumnConfiguration) -> Result<[TableCell], TableViewError> {
//        tableView.insertColumn(at: index, configuration: configuration)
//    }

    /// Deletes the row at given index
    /// - Parameter index: Index to delete
    public func deleteRow(at index: Int) {
        tableView.deleteRow(at: index)
    }

    /// Deletes the column at given index
    /// - Parameter index: Index to delete
    public func deleteColumn(at index: Int) {
        tableView.deleteColumn(at: index)
    }

    /// Freezes all the columns from 0 to the index provided
    /// - Parameter maxIndex: Index to freeze upto
    public func freezeColumns(upTo maxIndex: Int) {
        tableView.frozenColumnMaxIndex = maxIndex
    }

    /// Freezes all the rows from 0 to the index provided
    /// - Parameter maxIndex: Index to freeze upto
    public func freezeRows(upTo maxIndex: Int) {
        tableView.frozenRowMaxIndex = maxIndex
    }

    public func unfreezeColumns() {
        tableView.frozenColumnMaxIndex = nil
    }

    public func unfreezeRows() {
        tableView.frozenRowMaxIndex = nil
    }

    public func collapseRow(at index: Int) {
        tableView.collapseRow(at: index)
    }

    func expandRow(at index: Int) {
        tableView.expandRow(at: index)
    }

    func collapseColumn(at index: Int) {
        tableView.collapseColumn(at: index)
    }

    func expandColumn(at index: Int) {
        tableView.expandColumn(at: index)
    }

    func getCollapsedRowIndices() -> [Int] {
        return tableView.getCollapsedRowIndices()
    }

    func getCollapsedColumnIndices() -> [Int] {
        return tableView.getCollapsedColumnIndices()
    }

    /// Gets the cell at given row and column index. Indexes may be contained in a merged cell.
    /// - Parameters:
    ///   - rowIndex: Row index for the cell
    ///   - columnIndex: Column index for the cell
    /// - Returns: Cell at given row and column, if exists`
    public func cellAt(rowIndex: Int, columnIndex: Int) -> TableCell? {
        return tableView.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    /// Scrolls the cell at given index into viewable area. Indexes may be contained in a merged cell.
    /// - Parameters:
    ///   - rowIndex: Row index of the cell
    ///   - columnIndex: Column index for the cell
    ///   - animated: Animates scroll if `true`
    public func scrollToCellAt(rowIndex: Int, columnIndex: Int, animated: Bool = false) {
        if let cell = cellAt(rowIndex: rowIndex, columnIndex: columnIndex) {
            tableView.scrollTo(cell: cell, animated: animated)
        }
    }

    /// Applies style to row at given index
    /// - Parameters:
    ///   - style: Style to apply
    ///   - index: Index of the row
    public func applyStyle(_ style: GridCellStyle, toRow index: Int) {
        for cell in cells where cell.rowSpan.contains (index) {
            cell.contentView?.applyStyle(style)
        }
    }

    /// Applies style to column at given index
    /// - Parameters:
    ///   - style: Style to apply
    ///   - index: Index of the column
    public func applyStyle(_ style: GridCellStyle, toColumn index: Int) {
        for cell in cells where cell.columnSpan.contains (index) {
            cell.contentView?.applyStyle(style)
        }
    }

    private func resetShadows() {
        if let frozenColumnMaxIndex {
            let frozenColumnWidth = tableView.columnWidths.prefix(upTo: frozenColumnMaxIndex + 1).reduce(0) { partialResult, dimension in
                let viewport = tableView.bounds
                return partialResult + dimension.value(basedOn: frame.size.width, viewportWidth: viewport.width)
            }
            let borderOffSet = self.config.style.borderWidth
            leadingShadowConstraint.constant = frozenColumnWidth + borderOffSet
            leadingShadowView.isHidden = tableView.contentOffset.x < 1
        } else {
            leadingShadowView.isHidden = tableView.contentOffset.x <= 0
        }

        trailingShadowView.isHidden = tableView.contentOffset.x + tableView.bounds.width >= tableView.contentSize.width
    }
}

extension TableView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        resetShadows()
        viewportChanged()
    }
}

extension TableView: TableContentViewDelegate {
    var containerScrollView: UIScrollView? {
        delegate?.containerScrollView
    }

    var viewport: CGRect? {
        self.delegate?.viewport
    }

    func tableContentView(_ tableContentView: TableContentView, didCompleteLayoutWithBounds bounds: CGRect) {
        resetShadows()
    }

    func tableContentView(_ tableContentView: TableContentView, didLayoutCell cell: TableCell) {
        delegate?.tableView(self, didLayoutCell: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didSelectCells cells: [TableCell]) {
        delegate?.tableView(self, didSelectCells: cells)
    }

    func tableContentView(_ tableContentView: TableContentView, didUnselectCells cells: [TableCell]) {
        delegate?.tableView(self, didUnselectCells: cells)
    }

    func tableContentView(_ tableContentView: TableContentView, didReceiveFocusAt range: NSRange, in cell: TableCell) {
        resetColumnResizingHandles(selectedCell: cell)
        delegate?.tableView(self, didReceiveFocusAt: range, in: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didLoseFocusFrom range: NSRange, in cell: TableCell) {
        removeSelectionBorders()
        delegate?.tableView(self, didLoseFocusFrom: range, in: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: TableCell) {
        delegate?.tableView(self, didTapAtLocation: location, characterRange: characterRange, in: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: TableCell) {
        delegate?.tableView(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType, in: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didChangeBounds bounds: CGRect, in cell: TableCell) {
        delegate?.tableView(self, didChangeBounds: bounds, in: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didReceiveKey key: EditorKey, at range: NSRange, in cell: TableCell) {
        delegate?.tableView(self, didReceiveKey: key, at: range, in: cell)
    }

    func tableContentView(_ tableContentView: TableContentView, didAddNewRowAt index: Int) {
        if let cell = tableView.cellAt(rowIndex: index, columnIndex: 0) {
            cell.setFocus()
            tableView.scrollTo(cell: cell)
        }
    }

    func tableContentView(_ tableContentView: TableContentView, didUpdateCells cells: [TableCell]) {
        viewportChanged()
    }

    func tableContentView(_ tableContentView: TableContentView, didAddNewColumnAt index: Int) {
        if let cell = tableView.cellAt(rowIndex: 0, columnIndex: index) {
            cell.setFocus()
            tableView.scrollTo(cell: cell)
        }
    }

    func tableContentView(_ tableContentView: TableContentView, didDeleteRowAt index: Int) {
    }

    func tableContentView(_ tableContentView: TableContentView, didDeleteColumnAt index: Int) {
    }

    func tableContentView(_ tableContentView: TableContentView, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool {
        delegate?.tableView(self, shouldChangeColumnWidth: proposedWidth, for: columnIndex) ?? true
    }

    func tableContentView(_ tableContentView: TableContentView, cell: TableCell, didChangeBackgroundColor color: UIColor?, oldColor: UIColor?) {
    }
}

class TableCellHandleButton: UIButton {
    let cell: TableCell

    init(cell: TableCell, cornerRadius: CGFloat) {
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

extension TableView: AsyncDeferredRenderable { }

extension TableView: BackgroundColorObserving {
    public func containerEditor(_ editor: EditorView, backgroundColorUpdated color: UIColor?, oldColor: UIColor?) {
        backgroundColor = color
    }
}
