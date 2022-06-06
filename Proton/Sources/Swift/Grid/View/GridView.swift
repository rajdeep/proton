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

public enum GridCellDimension {
    case fixed(CGFloat)
    case fractional(CGFloat)

    public func value(basedOn total: CGFloat) -> CGFloat {
        switch self {
        case .fixed(let value):
            return value
        case .fractional(let value):
            return value * total
        }
    }
}

public struct GridConfiguration {
    public let numberOfRows: Int
    public let numberOfColumns: Int

    public let minColumnWidth: CGFloat
    public let maxColumnWidth: CGFloat

    public let minRowHeight: CGFloat
    public let maxRowHeight: CGFloat

    public static let `default` = GridConfiguration(numberOfRows: 2, numberOfColumns: 3, minColumnWidth: 100, maxColumnWidth: 200, minRowHeight: 40, maxRowHeight: 400)
}

public class GridView: UIView {
    let grid: Grid
    let config: GridConfiguration
    weak var boundsObserver: BoundsObserving?

    init(config: GridConfiguration = .default) {
        self.config = config
        let cells = Self.generateCells(config: config)
        grid = Grid(config: config, cells: cells)
        super.init(frame: .zero)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        return grid.sizeThatFits(size: frame.size)
    }

    public override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else { return }
            recalculateCellBounds()
        }
    }

    private func setup() {
        for cell in grid.cells {
            cell.contentView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(cell.contentView)
            let frame = grid.frameForCell(cell, basedOn: frame.size)
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

    private func recalculateCellBounds() {
        for c in grid.cells {
            // TODO: Optimize to recalculate frames for affected cells only i.e. row>=current
            let frame = grid.frameForCell(c, basedOn: bounds.size)
            c.contentView.frame = frame
            c.widthAnchorConstraint.constant = frame.width
            c.heightAnchorConstraint.constant = frame.height
            c.topAnchorConstraint.constant = frame.minY
            c.leadingAnchorConstraint.constant = frame.minX
        }

        boundsObserver?.didChangeBounds(CGRect(origin: bounds.origin, size: frame.size))
        invalidateIntrinsicContentSize()
    }

    private static func generateCells(config: GridConfiguration) -> [GridCell] {
        var cells = [GridCell]()
        for row in 0..<config.numberOfRows {
            for column in 0..<config.numberOfColumns {
                let cell = GridCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    style: GridCellConfiguration(minRowHeight: config.minRowHeight, maxRowHeight: config.maxRowHeight)
                )
                cells.append(cell)
            }
        }
        return cells
    }
}

extension GridView: GridCellDelegate {
    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect) {
        if let row = cell.rowSpan.first,
           grid.rowHeights.count > row {
            grid.rowHeights[row] = .fixed(bounds.height)
        }

        recalculateCellBounds()

    }
}

extension GridView: DynamicBoundsProviding {
    public func sizeFor(attachment: Attachment, containerSize: CGSize, lineRect: CGRect) -> CGSize {
        return grid.sizeThatFits(size: frame.size)
    }
}
