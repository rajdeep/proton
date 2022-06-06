//
//  Grid.swift
//  Proton
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

class Grid {
    private(set) var cells = [GridCell]()
    private let config: GridConfiguration

    var rowHeights = [CGFloat]()
    var columnWidths = [GridColumnDimension]()

    init(config: GridConfiguration, cells: [GridCell]) {
        self.config = config

        for column in config.columnsConfiguration {
            self.columnWidths.append(column.dimension)
        }

        for row in config.rowsConfiguration {
            self.rowHeights.append(row.minRowHeight)
        }
        self.cells = cells
    }

    func frameForCell(_ cell: GridCell, basedOn size: CGSize) -> CGRect {
        var x: CGFloat = 0
        var y: CGFloat = 0

        guard let minColumnSpan = cell.columnSpan.min(),
              let minRowSpan = cell.rowSpan.min() else {
            return .zero
        }

        if minColumnSpan > 0 {
            x = columnWidths[0..<minColumnSpan].reduce(0.0) { $0 + $1.value(basedOn: size.width)}
        }

        if minRowSpan > 0 {
            y = rowHeights[0..<minRowSpan].reduce(0.0, +)
        }

        var width: CGFloat = 0
        for col in cell.columnSpan {
            width += columnWidths[col].value(basedOn: size.width)
        }

        var height: CGFloat = 0
        for row in cell.rowSpan {
            height += rowHeights[row]
        }
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func sizeThatFits(size: CGSize) -> CGSize {
        let width = columnWidths.reduce(0.0) { $0 + $1.value(basedOn: size.width)}
        let height = rowHeights.reduce(0.0, +)
        return CGSize(width: width, height: height)
    }

    func maxContentHeightCellForRow(at index: Int) -> GridCell? {
        //TODO: account for merged rows
        let cells = cells.filter { $0.rowSpan.contains(index) }
        var maxHeightCell: GridCell?
        for cell in cells {
            if cell.contentSize.height > maxHeightCell?.contentSize.height ?? 0 {
                maxHeightCell = cell
            }
        }
        return maxHeightCell
    }
}
