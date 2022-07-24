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

public protocol GridViewDelegate: AnyObject {
    func gridView(_ gridView: GridView, didReceiveFocusAt range: NSRange, in cell: GridCell)
    func gridView(_ gridView: GridView, didLoseFocusFrom range: NSRange, in cell: GridCell)
    func gridView(_ gridView: GridView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell)
    func gridView(_ gridView: GridView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell)
    func gridView(_ gridView: GridView, didChangeBounds bounds: CGRect, in cell: GridCell)
    func gridView(_ gridView: GridView, didSelectCells cells: [GridCell])
    func gridView(_ gridView: GridView, didUnselectCells cells: [GridCell])
    func gridView(_ gridView: GridView, didReceiveKey key: EditorKey, at range: NSRange, in cell: GridCell)

    func gridView(_ gridView: GridView, didTapColumnActionButtonFor column: [Int], selectedCell cell: GridCell)
    func gridView(_ gridView: GridView, didTapRowActionButtonFor row: [Int], selectedCell cell: GridCell)
}

public class GridView: UIView {
    let gridView: GridContentView
    private var columnResizingHandles = [CellHandleButton]()
    private var insertRowButtons = [CellHandleButton]()

    private let handleSize: CGFloat = 20
    private let config: GridConfiguration

    public var delegate: GridViewDelegate?

    public var boundsObserver: BoundsObserving? {
        get { gridView.boundsObserver }
        set { gridView.boundsObserver = newValue }
    }

    private let selectionView = SelectionView()

    public var selectionColor: UIColor?

    public var isSelected: Bool = false {
        didSet {
            if isSelected {
                selectionView.addTo(parent: self, selectionColor: selectionColor)
            } else {
                selectionView.removeFromSuperview()
            }
        }
    }

    public var cells: [GridCell] {
        gridView.cells
    }

    public var selectedCells: [GridCell] {
        gridView.selectedCells
    }

    public init(config: GridConfiguration, initialSize: CGSize) {
        self.gridView = GridContentView(config: config, initialSize: initialSize)
        self.config = config
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showCellResizingHandles() {
        columnResizingHandles.forEach { $0.isHidden = false }
    }

    public func hideCellResizingHandles() {
        columnResizingHandles.forEach { $0.isHidden = true }
    }

    public func showAddRowButtons() {
        insertRowButtons.forEach { $0.isHidden = false }
    }

    public func hideAddRowButtons() {
        insertRowButtons.forEach { $0.isHidden = true }
    }

    private func setup() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.gridContentViewDelegate = self
//        layer.borderWidth = 1
//        layer.borderColor = UIColor.red.cgColor

        addSubview(gridView)
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: topAnchor, constant: handleSize),
            gridView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: handleSize),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        ])
//        addColumnResizingHandles()
//        hideCellResizingHandles()
//
//        addInsertRowButtons()
//        hideAddRowButtons()
    }

    var columnActionButton: CellHandleButton!
    var rowActionButton: CellHandleButton!


    var columnRightBorderView: CellHandleButton!
    var columnLeftBorderView: CellHandleButton!
    var columnTopBorderView: CellHandleButton!
    var columnBottomBorderView: CellHandleButton!

    private func addCellActionsButton(cell: GridCell) {
        guard let image = config.accessory.resizeColumnHandleImage else { return }
        columnActionButton = makeColumnResizingHandle(cell: cell, image: image)
        rowActionButton = makeColumnResizingHandle(cell: cell, image: image)

        columnActionButton.addTarget(self, action: #selector(didTapColumnActionButton(sender:)), for: .touchUpInside)
        rowActionButton.addTarget(self, action: #selector(didTapRowActionButton(sender:)), for: .touchUpInside)

        columnRightBorderView = makeColumnResizingHandle(cell: cell, image: image)
        columnRightBorderView.backgroundColor = cell.gridStyle.borderColor

        columnLeftBorderView = makeColumnResizingHandle(cell: cell, image: image)
        columnLeftBorderView.backgroundColor = cell.gridStyle.borderColor

        columnTopBorderView = makeColumnResizingHandle(cell: cell, image: image)
        columnTopBorderView.backgroundColor = cell.gridStyle.borderColor

        columnBottomBorderView = makeColumnResizingHandle(cell: cell, image: image)
        columnBottomBorderView.backgroundColor = cell.gridStyle.borderColor

        addSubview(columnActionButton)
        addSubview(rowActionButton)

        addSubview(columnRightBorderView)
        addSubview(columnLeftBorderView)
        addSubview(columnTopBorderView)
        addSubview(columnBottomBorderView)

        columnRightBorderView.alpha = 0.3
        columnLeftBorderView.alpha = 0.3
        columnTopBorderView.alpha = 0.3
        columnBottomBorderView.alpha = 0.3

        NSLayoutConstraint.activate([
            columnActionButton.bottomAnchor.constraint(equalTo: gridView.topAnchor, constant: -2),
            columnActionButton.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            columnActionButton.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor),
            columnActionButton.heightAnchor.constraint(equalToConstant: 15),

            rowActionButton.trailingAnchor.constraint(equalTo: gridView.leadingAnchor, constant: -2),
            rowActionButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            rowActionButton.widthAnchor.constraint(equalToConstant: 15),
            rowActionButton.heightAnchor.constraint(equalTo: cell.contentView.heightAnchor),

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

    @objc
    private func didTapColumnActionButton(sender: CellHandleButton) {
        delegate?.gridView(self, didTapColumnActionButtonFor: sender.cell.columnSpan, selectedCell: sender.cell)
    }

    @objc
    private func didTapRowActionButton(sender: CellHandleButton) {
        delegate?.gridView(self, didTapRowActionButtonFor: sender.cell.rowSpan, selectedCell: sender.cell)
    }

    private func addColumnResizingHandles() {
        guard let image = config.accessory.resizeColumnHandleImage else { return }
        for cell in cells {
            let handleView = makeColumnResizingHandle(cell: cell, image: image)
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
    }

    private func resetColumnResizingHandles() {
        columnResizingHandles.forEach { $0.removeFromSuperview() }
        addColumnResizingHandles()
    }

    private func addInsertRowButtons() {
        guard let image = config.accessory.addRowButtonImage else { return }
        for cell in cells {
            if cell.columnSpan.contains(0) {
                let button = makeInsertRowButtons(cell: cell, image: image)
                insertRowButtons.append(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                addSubview(button)
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: handleSize),
                    button.heightAnchor.constraint(equalTo: button.widthAnchor),
                    button.trailingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 5),
                    button.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])
            }
        }
    }

    private func addInsertColumnButtons() {
        guard let image = config.accessory.addColumnButtonImage else { return }
        for cell in cells {
            if cell.rowSpan.contains(0) {
                let button = makeInsertRowButtons(cell: cell, image: image)
                insertRowButtons.append(button)
                button.translatesAutoresizingMaskIntoConstraints = false
                addSubview(button)
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: handleSize),
                    button.heightAnchor.constraint(equalTo: button.widthAnchor),
                    button.bottomAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5),
                    button.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor)
                ])
            }
        }
    }

    private func resetInsertRowButtons() {
        insertRowButtons.forEach { $0.removeFromSuperview() }
        addInsertRowButtons()
    }

    private func makeColumnResizingHandle(cell: GridCell, image: UIImage) -> CellHandleButton {
        let dragHandle = CellHandleButton(cell: cell, image: image)
        dragHandle.layer.borderColor = UIColor.black.cgColor
        dragHandle.layer.borderWidth = 1
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handler(gesture:))))
        return dragHandle
    }

    private func makeInsertRowButtons(cell: GridCell, image: UIImage) -> CellHandleButton {
        let button = CellHandleButton(cell: cell, image: image)
        button.addTarget(self, action: #selector(addRowButtonClicked(button:)), for: .touchUpInside)
        return button
    }

    @objc
    func addRowButtonClicked(button: CellHandleButton) {
        guard let index = button.cell.rowSpan.max() else { return }
        insertRow(at: index + 1, configuration: GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400))
    }

    private var lastLocation: CGPoint? = nil
    @objc
    func handler(gesture: UIPanGestureRecognizer){
        guard let draggedView = gesture.view,
              let cell = (draggedView as? CellHandleButton)?.cell else { return }

        let location = gesture.location(in: self)
        if gesture.state == .changed {
            if let lastLocation = lastLocation {
                let deltaX = location.x - lastLocation.x
                gridView.changeColumnWidth(index: cell.columnSpan.max() ?? 0, delta: deltaX)
            }
            lastLocation = location
        }

        if gesture.state == .ended
            || gesture.state == .cancelled
            || gesture.state == .ended {
            lastLocation = nil
        }
    }

    public func isCellSelectionMergeable(_ cells: [GridCell]) -> Bool {
        gridView.isMergeable(cells: cells)
    }

    public func merge(cells: [GridCell]) {
        gridView.merge(cells: cells)
//        resetColumnResizingHandles()
    }

    public func split(cell: GridCell) {
        gridView.split(cell: cell)
//        resetColumnResizingHandles()
    }

    public func insertRow(at index: Int, configuration: GridRowConfiguration) {
        gridView.insertRow(at: index, configuration: configuration)
    }

    public func insertColumn(at index: Int, configuration: GridColumnConfiguration) {
        gridView.insertColumn(at: index, configuration: configuration)
    }

    public func deleteRow(at index: Int) {
        gridView.deleteRow(at: index)
    }

    public func deleteColumn(at index: Int) {
        gridView.deleteColumn(at: index)
    }

    public func cellAt(rowIndex: Int, columnIndex: Int) -> GridCell? {
        return gridView.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    public func scrollToCellAt(rowIndex: Int, columnIndex: Int, animated: Bool = true) {
        if let cell = cells.first(where: { $0.rowSpan.contains( rowIndex) && $0.columnSpan.contains(columnIndex) }) {
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
//        showCellResizingHandles()
//        showAddRowButtons()
        addCellActionsButton(cell: cell)
        delegate?.gridView(self, didReceiveFocusAt: range, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didLoseFocusFrom range: NSRange, in cell: GridCell) {
//        hideCellResizingHandles()
//        hideAddRowButtons()
        columnActionButton.removeFromSuperview()
        rowActionButton.removeFromSuperview()
        columnRightBorderView.removeFromSuperview()
        columnLeftBorderView.removeFromSuperview()
        columnTopBorderView.removeFromSuperview()
        columnBottomBorderView.removeFromSuperview()
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
//        resetColumnResizingHandles()
//        resetInsertRowButtons()
        if let cell = gridView.cellAt(rowIndex: index, columnIndex: 0) {
            cell.setFocus()
            gridView.scrollTo(cell: cell)
        }
    }

    func gridContentView(_ gridContentView: GridContentView, didAddNewColumnAt index: Int) {
//        resetColumnResizingHandles()
//        resetInsertRowButtons()
        if let cell = gridView.cellAt(rowIndex: 0, columnIndex: index) {
            cell.setFocus()
            gridView.scrollTo(cell: cell)
        }
    }

    func gridContentView(_ gridContentView: GridContentView, didDeleteRowAt index: Int) {
//        resetColumnResizingHandles()
//        resetInsertRowButtons()
    }

    func gridContentView(_ gridContentView: GridContentView, didDeleteColumnAt index: Int) {
//        resetColumnResizingHandles()
//        resetInsertRowButtons()
    }
}

class CellHandleButton: UIButton {
    let cell: GridCell

    init(cell: GridCell, image: UIImage) {
        self.cell = cell
        super.init(frame: .zero)
        setImage(image, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
