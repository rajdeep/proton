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
import UIKit

public struct GridStyle {
    public var borderColor: UIColor
    public var borderWidth: CGFloat

    public static var `default` = GridStyle(borderColor: .gray, borderWidth: 1)

    public init(
        borderColor: UIColor,
        borderWidth: CGFloat) {
            self.borderColor = borderColor
            self.borderWidth = borderWidth
        }
}

public struct GridCellStyle {
    public var backgroundColor: UIColor?
    public var textColor: UIColor?
    public var font: UIFont?

    public init(
        backgroundColor: UIColor? = nil,
        textColor: UIColor? = nil,
        font: UIFont? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
    }

    public static func merged(style: GridCellStyle, other: GridCellStyle) -> GridCellStyle {
        GridCellStyle(
            backgroundColor: style.backgroundColor ?? other.backgroundColor,
            textColor: style.textColor ?? other.textColor,
            font: style.font ?? other.font)
    }
}

protocol GridCellDelegate: AnyObject {
    func cell(_ cell: GridCell, didChangeBounds bounds: CGRect)
    func cell(_ cell: GridCell, didReceiveFocusAt range: NSRange)
    func cell(_ cell: GridCell, didLoseFocusFrom range: NSRange)
    func cell(_ cell: GridCell, didTapAtLocation location: CGPoint, characterRange: NSRange?)
    func cell(_ cell: GridCell, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name)
    func cell(_ cell: GridCell, didReceiveKey key: EditorKey, at range: NSRange)
}

public class GridCell {
    var id: String {
        "{\(rowSpan),\(columnSpan)}"
    }
    public internal(set) var rowSpan: [Int]
    public internal(set) var columnSpan: [Int]

    public internal(set) var frame: CGRect = .zero

    private var selectionView: SelectionView?

    public var isSelected: Bool {
        get { selectionView?.superview != nil }
        set {
            if newValue {
                selectionView?.addTo(parent: contentView)
            } else {
                selectionView?.removeFromSuperview()
            }
        }
    }

    public let editor = EditorView()

    public var isSplittable: Bool {
        rowSpan.count > 1 || columnSpan.count > 1
    }

    public var contentSize: CGSize {
        editor.frame.size
    }

    public let contentView = UIView()

    let style: GridCellStyle
    let gridStyle: GridStyle

    let widthAnchorConstraint: NSLayoutConstraint
    let heightAnchorConstraint: NSLayoutConstraint

    var topAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!

    weak var delegate: GridCellDelegate?

    let initialHeight: CGFloat

    init(rowSpan: [Int], columnSpan: [Int], initialHeight: CGFloat, style: GridCellStyle = .init(), gridStyle: GridStyle = .default) {
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.style = style
        self.gridStyle = gridStyle
        self.initialHeight = initialHeight
        self.contentView.layoutMargins = .zero

        widthAnchorConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        updateStyle(style: style)

        self.selectionView = SelectionView { [weak self] in
            self?.isSelected = false
        }

        setup()
    }

    public func setFocus() {
        editor.setFocus()
    }

    public func removeFocus() {
        editor.resignFocus()
    }

    func updateStyle(style: GridCellStyle) {
        contentView.layer.borderColor = UIColor.gray.cgColor
        contentView.layer.borderWidth = 1

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contentViewTapped))
        contentView.addGestureRecognizer(tapGestureRecognizer)

        contentView.layer.borderColor = gridStyle.borderColor.cgColor
        contentView.layer.borderWidth = gridStyle.borderWidth

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
        editor.delegate = self
        contentView.addSubview(editor)

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            editor.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: initialHeight)
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

extension GridCell: EditorViewDelegate {
    public func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        delegate?.cell(self, didReceiveFocusAt: range)
    }

    public func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) {
        delegate?.cell(self, didLoseFocusFrom: range)
    }

    public func editor(_ editor: EditorView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        delegate?.cell(self, didTapAtLocation: location, characterRange: characterRange)
    }

    public func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        delegate?.cell(self, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    public func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange) {
        delegate?.cell(self, didReceiveKey: key, at: range)
    }
}

extension GridCell: Equatable {
    public static func ==(lhs: GridCell, rhs: GridCell) -> Bool {
        return lhs.id == rhs.id
    }
}
