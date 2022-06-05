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

public struct GridConfiguration {
    let numberOfRows: Int
    let numberOfColumns: Int

    let minColumnWidth: CGFloat
    let maxColumnWidth: CGFloat

    let minRowHeight: CGFloat
    let maxRowHeight: CGFloat
}

public class GridView: UIView {
    let grid: Grid
    let config: GridConfiguration

    init(config: GridConfiguration = GridConfiguration(numberOfRows: 2, numberOfColumns: 3, minColumnWidth: 100, maxColumnWidth: 200, minRowHeight: 40, maxRowHeight: 400)) {
        self.config = config
        grid = Grid(columnCount: config.numberOfColumns, rowCount: config.numberOfRows, columnWidth: config.minColumnWidth, rowHeight: config.minRowHeight)
        super.init(frame: .zero)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        grid.size
    }

    private func setup() {
        for cell in grid.cells {
            cell.contentView.translatesAutoresizingMaskIntoConstraints = false

            let editor = EditorView()
            editor.translatesAutoresizingMaskIntoConstraints = false

            cell.contentView.addSubview(editor)

            NSLayoutConstraint.activate([
                editor.topAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.topAnchor),
                editor.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
                editor.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
                editor.heightAnchor.constraint(greaterThanOrEqualToConstant: config.minRowHeight),
                editor.heightAnchor.constraint(lessThanOrEqualToConstant: config.maxRowHeight)
//                editor.bottomAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.bottomAnchor),
            ])

            addSubview(cell.contentView)
            let frame = grid.frameForCell(cell)
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
        }
    }
}

//extension GridView: GridCellDelegate {
//    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect) {
//        if let row = cell.rows.first,
//           grid.rowHeights.count > row {
//            grid.rowHeights[row] = bounds.height
//        }
//
//        for c in grid.cells {
////            if c.rows.first! >= cell.rows.first!  {
//                let frame = grid.frameForCell(c)
//                c.contentView.frame = frame
//                c.widthAnchorConstraint.constant = frame.width
//                c.heightAnchorConstraint.constant = frame.height
//                c.topAnchorConstraint.constant = frame.minY
//                c.leadingAnchorConstraint.constant = frame.minX
////            }
//        }
//    }
//}
