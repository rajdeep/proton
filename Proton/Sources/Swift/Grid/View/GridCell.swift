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
    public var borderColor: UIColor?
    public var borderWidth: CGFloat?
    public var cornerRadius: CGFloat?
    public var backgroundColor: UIColor?
    public var textColor: UIColor?
    public var font: UIFont?

    public init(
        borderColor: UIColor? = nil,
        borderWidth: CGFloat? = nil,
        cornerRadius: CGFloat? = nil,
        backgroundColor: UIColor? = nil,
        textColor: UIColor? = nil,
        font: UIFont? = nil
    ) {
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
    }

    public static func merged(style: GridCellStyle, other: GridCellStyle) -> GridCellStyle {
        GridCellStyle(
            borderColor: style.borderColor ?? other.borderColor,
            borderWidth: style.borderWidth ?? other.borderWidth,
            cornerRadius: style.cornerRadius ?? other.cornerRadius,
            backgroundColor: style.backgroundColor ?? other.backgroundColor,
            textColor: style.textColor ?? other.textColor,
            font: style.font ?? other.font)
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
    var cachedFrame: CGRect = .zero


    private let selectionView = SelectionView()

    var isSelected: Bool = false {
        didSet {
            if isSelected {
                selectionView.addTo(parent: contentView)
            } else {
                selectionView.removeFromSuperview()
            }
        }
    }

    public let editor = EditorView()

    var isSplittable: Bool {
        rowSpan.count > 1 || columnSpan.count > 1
    }

    var contentSize: CGSize {
        editor.frame.size
    }

    let contentView = UIView()

    let style: GridCellStyle

    let widthAnchorConstraint: NSLayoutConstraint
    let heightAnchorConstraint: NSLayoutConstraint

    var topAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!

    weak var delegate: GridCellDelegate?

    let minHeight: CGFloat
    let maxHeight: CGFloat

    init(rowSpan: [Int], columnSpan: [Int], minHeight: CGFloat, maxHeight: CGFloat, style: GridCellStyle = .init()) {
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.style = style
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        //TODO: Move to config
        self.contentView.layoutMargins = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

        widthAnchorConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        updateStyle(style: style)

        setup()
    }

    func updateStyle(style: GridCellStyle) {
        contentView.layer.borderColor = UIColor.gray.cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 2

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contentViewTapped))
        contentView.addGestureRecognizer(tapGestureRecognizer)

        if let borderColor = style.borderColor?.cgColor {
            contentView.layer.borderColor = borderColor
        }
        if let borderWidth = style.borderWidth {
            contentView.layer.borderWidth = borderWidth
        }
        if let cornerRadius = style.cornerRadius {
            contentView.layer.cornerRadius = cornerRadius
            contentView.clipsToBounds = true
        }
        if let font = style.font {
            editor.font = font
        }
        if let textColor = style.textColor {
            editor.textColor = textColor
        }
        if let backgroundColor = style.backgroundColor {
            editor.backgroundColor = backgroundColor
            contentView.backgroundColor = backgroundColor
        }
    }

    @objc
    private func contentViewTapped() {
        editor.becomeFirstResponder()
    }

    private func setup() {
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.boundsObserver = self
        contentView.addSubview(editor)

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            editor.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight)
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
