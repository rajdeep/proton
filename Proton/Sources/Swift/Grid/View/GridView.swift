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

    var cells: [GridCell] {
        gridView.cells
    }

    public init(config: GridConfiguration, initialSize: CGSize) {
        self.gridView = GridContentView(config: config, initialSize: initialSize)
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

    public func merge(cell: GridCell, other: GridCell) {
        gridView.merge(cell: cell, other: other)
        gridView.invalidateCellLayout()
    }

    public func split(cell: GridCell) {
        gridView.split(cell: cell)
        gridView.invalidateCellLayout()
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
