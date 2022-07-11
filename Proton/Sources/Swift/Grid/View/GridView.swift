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
}

public class GridView: UIView {
    let gridView: GridContentView
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
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let handleSize: CGFloat = 25
    private func setup() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.gridContentViewDelegate = self
//        layer.borderWidth = 1
//        layer.borderColor = UIColor.red.cgColor

        addSubview(gridView)
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            gridView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -handleSize/2),
            gridView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            gridView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -handleSize/2)
        ])
        addHandles()
    }


    private var dragHandles = [CellDragHandleView]()
    private func addHandles() {
        for cell in cells {
            let handleView = makeDragHandle(cell: cell, orientation: .horizontal)
            dragHandles.append(handleView)
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

    private func resetDragHandles() {
        dragHandles.forEach { $0.removeFromSuperview() }
        addHandles()
    }

    func makeDragHandle(cell: GridCell, orientation: CellDragHandleView.Orientation) -> CellDragHandleView {
        let dragHandle = CellDragHandleView(cell: cell, orientation: orientation)
        dragHandle.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handler(gesture:))))
        return dragHandle
    }

    private var lastLocation: CGPoint = .zero
    @objc func handler(gesture: UIPanGestureRecognizer){
        guard let draggedView = gesture.view,
              let cell = (draggedView as? CellDragHandleView)?.cell
        else { return }
        let location = gesture.location(in: self)

        if gesture.state == .began {
            lastLocation = draggedView.center
        }

        if gesture.state == .changed {
            let deltaX = location.x - lastLocation.x
            lastLocation = location
            gridView.changeColumnWidth(index: cell.columnSpan.max() ?? 0, delta: deltaX)
        }

        if gesture.state == .ended {
            lastLocation = draggedView.center
        }
    }

    public func isCellSelectionMergeable(_ cells: [GridCell]) -> Bool {
        gridView.isMergeable(cells: cells)
    }

    public func merge(cells: [GridCell]) {
        gridView.merge(cells: cells)
        resetDragHandles()
    }

    public func split(cell: GridCell) {
        gridView.split(cell: cell)
        resetDragHandles()
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
        delegate?.gridView(self, didReceiveFocusAt: range, in: cell)
    }

    func gridContentView(_ gridContentView: GridContentView, didLoseFocusFrom range: NSRange, in cell: GridCell) {
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
}

class CellDragHandleView: UIView {
    enum Orientation {
        case horizontal
        case vertical
    }

    let imageView = UIImageView()
    let cell: GridCell
    let orientation: Orientation
    var leadingAnchorConstraint: NSLayoutConstraint!

    init(cell: GridCell, orientation: Orientation) {
        self.cell = cell
        self.orientation = orientation
        super.init(frame: .zero)
        setup()
    }

    private func setup() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        if #available(iOSApplicationExtension 13.0, *) {
            self.imageView.image = UIImage(systemName: "arrow.left.and.right")
        } else {
            self.backgroundColor = tintColor
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
