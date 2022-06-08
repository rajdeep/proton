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

class GridContentView: UIScrollView {
    private let grid: Grid
    let config: GridConfiguration
    let initialSize: CGSize
    weak var boundsObserver: BoundsObserving?

    var cells: [GridCell] {
        grid.cells
    }

    init(config: GridConfiguration, initialSize: CGSize) {
        self.config = config
        self.initialSize = initialSize
        let cells = Self.generateCells(config: config)
        grid = Grid(config: config, cells: cells)
        super.init(frame: .zero)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = grid.sizeThatFits(size: frame.size)
        self.contentSize = size
        self.isScrollEnabled = size.width > frame.width
        self.alwaysBounceHorizontal = isScrollEnabled
        return grid.sizeThatFits(size: frame.size)
    }

    override var bounds: CGRect {
        didSet {
            guard oldValue != bounds else { return }
            recalculateCellBounds()
        }
    }

    func scrollTo(cell: GridCell, animated: Bool = true) {
        let frame = grid.frameForCell(cell, basedOn: contentSize)
        self.scrollRectToVisible(frame, animated: animated)
    }

    func merge(cell: GridCell, other: GridCell) {
        grid.merge(cell: cell, other: other)
    }

    func cellAt(rowIndex: Int, columnIndex: Int) -> GridCell? {
        grid.cellAt(rowIndex: rowIndex, columnIndex: columnIndex)
    }

    private func setup() {
        for cell in grid.cells {
            cell.contentView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(cell.contentView)
            // Render with a high number for width/height to initialize
            // since Editor may not be (and most likely not initialized at init of GridView, having actual value causes autolayout errors
            // in combination with fractional widths
            //TODO: revisit - likely issue with the layout margin guides ie non-zero padding
            let frame = grid.frameForCell(cell, basedOn: initialSize)
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

    func invalidateCellLayout() {
        recalculateCellBounds()
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
            print("\(c.id): [\(frame)]")
        }

        boundsObserver?.didChangeBounds(CGRect(origin: bounds.origin, size: frame.size))
        invalidateIntrinsicContentSize()
    }

    private static func generateCells(config: GridConfiguration) -> [GridCell] {
        var cells = [GridCell]()
        for row in 0..<config.numberOfRows {
            let rowStyle = config.rowsConfiguration[row].style
            let minRowHeight = config.rowsConfiguration[row].minRowHeight
            let maxRowHeight = config.rowsConfiguration[row].maxRowHeight

            for column in 0..<config.numberOfColumns {
                let columnStyle = config.columnsConfiguration[column].style
                let mergedStyle = GridCellStyle.merged(style: rowStyle, other: columnStyle)
                let cell = GridCell(
                    rowSpan: [row],
                    columnSpan: [column],
                    minHeight: minRowHeight,
                    maxHeight: maxRowHeight,
                    style: mergedStyle
                )
                cells.append(cell)
            }
        }
        return cells
    }
}

extension GridContentView: GridCellDelegate {
    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect) {
        guard  let row = cell.rowSpan.first else { return }
        if grid.rowHeights.count > row,
           grid.maxContentHeightCellForRow(at: row)?.id == cell.id {
            grid.rowHeights[row] = bounds.height
        } else {
            grid.rowHeights[row] = grid.maxContentHeightCellForRow(at: row)?.contentSize.height ?? 0
        }

        recalculateCellBounds()

    }
}

extension GridContentView: DynamicBoundsProviding {
    public func sizeFor(attachment: Attachment, containerSize: CGSize, lineRect: CGRect) -> CGSize {
        guard bounds.size != .zero else { return .zero }
        return grid.sizeThatFits(size: frame.size)
    }
}
