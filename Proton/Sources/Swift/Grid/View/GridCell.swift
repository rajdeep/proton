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

public struct GridCellConfiguration {
    let borderColor: UIColor
    let borderWidth: CGFloat

    let cornerRadius: CGFloat

    let minRowHeight: CGFloat
    let maxRowHeight: CGFloat


    init(borderColor: UIColor = .gray, borderWidth: CGFloat = 0.5, cornerRadius: CGFloat = 2, minRowHeight: CGFloat = 40, maxRowHeight: CGFloat = 300) {
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.minRowHeight = minRowHeight
        self.maxRowHeight = maxRowHeight
    }
}

protocol GridCellDelegate: AnyObject {
    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect)
}

public class GridCell {
    var id: String {
        "{\(rowSpan),\(columnSpan)}"
    }
    var rowSpan: [Int]
    var columnSpan: [Int]

    public let editor = EditorView()

    var isMergedRows: Bool {
        rowSpan.count > 1
    }

    var isMergedColumns: Bool {
        columnSpan.count > 1
    }

    var contentSize: CGSize {
        editor.frame.size
    }

    let contentView = UIView()

    let style: GridCellConfiguration

    let widthAnchorConstraint: NSLayoutConstraint
    let heightAnchorConstraint: NSLayoutConstraint

    var topAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!

    weak var delegate: GridCellDelegate?

    init(rowSpan: [Int], columnSpan: [Int], style: GridCellConfiguration = .init()) {
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.style = style
        //TODO: Move to config
        self.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

        widthAnchorConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        contentView.layer.borderColor = style.borderColor.cgColor
        contentView.layer.borderWidth = style.borderWidth
        contentView.layer.cornerRadius = style.cornerRadius
        contentView.clipsToBounds = true

        setup()
    }

    private func setup() {
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.boundsObserver = self
        contentView.addSubview(editor)

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            editor.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: style.minRowHeight),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: style.maxRowHeight)
//                editor.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
//            topAnchorConstraint,
//            leadingAnchorConstraint,
            widthAnchorConstraint,
            heightAnchorConstraint
        ])

//        editor.layer.borderWidth = 1
//        editor.layer.borderColor = UIColor.red.cgColor
//
//        contentView.layer.borderWidth = 1
//        contentView.layer.borderColor = UIColor.green.cgColor


    }
}

extension GridCell: BoundsObserving {
    public func didChangeBounds(_ bounds: CGRect) {
        delegate?.cell(self, didChangeBounds: bounds)
    }
}
