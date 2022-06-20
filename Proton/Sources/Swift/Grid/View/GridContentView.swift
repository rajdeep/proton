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

protocol GridContentViewDelegate: AnyObject {
    func gridContentView(_ gridContentView: GridContentView, didReceiveFocusAt range: NSRange, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didLoseFocusFrom range: NSRange, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell)
    func gridContentView(_ gridContentView: GridContentView, didChangeBounds bounds: CGRect, in cell: GridCell)
}

class GridContentView: UIScrollView {
    private let grid: Grid
    let config: GridConfiguration
    let initialSize: CGSize
    weak var boundsObserver: BoundsObserving?
    weak var gridContentViewDelegate: GridContentViewDelegate?

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
        return size
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

    func merge(cells: [GridCell]) {
        grid.merge(cells: cells)
        invalidateCellLayout()
    }

    func split(cell: GridCell) {
        grid.split(cell: cell)
        invalidateCellLayout()
    }

    func insertRow(at index: Int, configuration: GridRowConfiguration) {
        grid.insertRow(at: index, config: configuration)
        invalidateCellLayout()
    }

    func insertColumn(at index: Int, configuration: GridColumnConfiguration) {
        grid.insertColumn(at: index, config: configuration)
        invalidateCellLayout()
    }

    func deleteRow(at index: Int) {
        grid.deleteRow(at: index)
        invalidateCellLayout()
    }

    func deleteColumn(at index: Int) {
        grid.deleteColumn(at: index)
        invalidateCellLayout()
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

            // Add to grid if this is a newly inserted cell after initial setup.
            // A new cell may exist as a result of inserting a new row/colum
            // or splitting an existing merged cell
            if c.contentView.superview == nil {
                addSubview(c.contentView)
                c.topAnchorConstraint = c.contentView.topAnchor.constraint(equalTo: topAnchor, constant: frame.minY)
                c.leadingAnchorConstraint = c.contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: frame.minX)
            }

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
                    style: mergedStyle,
                    gridStyle: config.style
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

        recalculateCellBounds()
        gridContentViewDelegate?.gridContentView(self, didChangeBounds: cell.cachedFrame, in: cell)
    }
}

extension GridContentView: DynamicBoundsProviding {
    public func sizeFor(attachment: Attachment, containerSize: CGSize, lineRect: CGRect) -> CGSize {
        guard bounds.size != .zero else { return .zero }
        return grid.sizeThatFits(size: frame.size)
    }
}
