//
//  GridCell.swift
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

public struct GridCellStyle {
    let borderColor: UIColor
    let borderWidth: CGFloat

    let cornerRadius: CGFloat

    init(borderColor: UIColor = .gray, borderWidth: CGFloat = 0.5, cornerRadius: CGFloat = 2) {
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }
}

public class GridCell {
    var id: String {
        "{\(rowSpan),\(columnSpan)}"
    }
    var rowSpan: [Int]
    var columnSpan: [Int]

    var isMergedRows: Bool {
        rowSpan.count > 1
    }

    var isMergedColumns: Bool {
        columnSpan.count > 1
    }

    var debugDescription: String {
        id
    }

    let contentView = UIView()
    let style: GridCellStyle


    let widthAnchorConstraint: NSLayoutConstraint
    let heightAnchorConstraint: NSLayoutConstraint

    var topAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!

    init(rowSpan: [Int], columnSpan: [Int], style: GridCellStyle = .init()) {
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.style = style
        self.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

        widthAnchorConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        contentView.layer.borderColor = style.borderColor.cgColor
        contentView.layer.borderWidth = style.borderWidth
        contentView.layer.cornerRadius = style.cornerRadius
        contentView.clipsToBounds = true
    }
}
