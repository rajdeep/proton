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

/// Style configuration for the grid
public struct GridStyle {

    /// Border color for grid
    public var borderColor: UIColor

    /// Border width for the grid
    public var borderWidth: CGFloat

    /// Default style
    public static var `default` = GridStyle(borderColor: .gray, borderWidth: 1)

    public init(
        borderColor: UIColor,
        borderWidth: CGFloat) {
            self.borderColor = borderColor
            self.borderWidth = borderWidth
        }
}

/// Style configuration for the `GridCell`
public struct GridCellStyle {

    /// Border style for individual cells. This may be used to override the style provided in the `GridStyle` for individual cells
    public struct BorderStyle {
        public var color: UIColor
        public var width: CGFloat

        public init(color: UIColor, width: CGFloat) {
            self.color = color
            self.width = width
        }
    }
    /// Default background color for the cell.
    public var backgroundColor: UIColor?

    /// Default text color for the cell
    public var textColor: UIColor?

    /// Default font for the cell
    public var font: UIFont?

    public var borderStyle: BorderStyle?

    public init(
        backgroundColor: UIColor? = nil,
        textColor: UIColor? = nil,
        font: UIFont? = nil,
        borderStyle: BorderStyle? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.borderStyle = borderStyle
    }

    /// Creates a merged styles from given styles with precedence to the first style and any missing values used from the second style
    /// - Parameters:
    ///   - style: Primary style
    ///   - other: Secondary style
    /// - Returns: Merged style
    public static func merged(style: GridCellStyle, other: GridCellStyle) -> GridCellStyle {
        GridCellStyle(
            backgroundColor: style.backgroundColor ?? other.backgroundColor,
            textColor: style.textColor ?? other.textColor,
            font: style.font ?? other.font,
            borderStyle: style.borderStyle ?? other.borderStyle
        )
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

/// Denotes a cell in the `GridView`
public class GridCell {
    var id: String {
        "{\(rowSpan),\(columnSpan)}"
    }

    /// Row indexes spanned by the cell. In case of a merged cell, this will contain all the rows= indexes which are merged.
    public internal(set) var rowSpan: [Int]
    /// Column indexes spanned by the cell. In case of a merged cell, this will contain all the column indexes which are merged.
    public internal(set) var columnSpan: [Int]

    /// Frame of the cell within `GridView`
    public internal(set) var frame: CGRect = .zero

    private var selectionView: SelectionView?

    /// Sets the cell selected
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

    /// Editor within the cell
    public let editor: EditorView

    /// Denotes if the cell can be split i.e. is a merged cell.
    public var isSplittable: Bool {
        rowSpan.count > 1 || columnSpan.count > 1
    }

    /// Content size of the cell
    public var contentSize: CGSize {
        editor.frame.size
    }

    /// Content view for the cell
    public let contentView = UIView()

    public let gridStyle: GridStyle

    let widthAnchorConstraint: NSLayoutConstraint
    let heightAnchorConstraint: NSLayoutConstraint

    var topAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!

    weak var delegate: GridCellDelegate?

    let initialHeight: CGFloat

    public init(editor: EditorView, rowSpan: [Int], columnSpan: [Int], initialHeight: CGFloat = 40, style: GridCellStyle = .init(), gridStyle: GridStyle = .default) {
        self.editor = editor
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.gridStyle = gridStyle
        self.initialHeight = initialHeight
        // Ensure Editor frame is .zero as otherwise it conflicts with some layout calculations
        self.editor.frame = .zero
        self.contentView.layoutMargins = .zero

        widthAnchorConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        applyStyle(style)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contentViewTapped))
        contentView.addGestureRecognizer(tapGestureRecognizer)

        self.selectionView = SelectionView { [weak self] in
            self?.isSelected = false
        }

        setup()
    }

    public convenience init(rowSpan: [Int], columnSpan: [Int], initialHeight: CGFloat = 40, style: GridCellStyle = .init(), gridStyle: GridStyle = .default) {
        self.init(editor: EditorView(), rowSpan: rowSpan, columnSpan: columnSpan, initialHeight: initialHeight, style: style, gridStyle: gridStyle)
    }

    /// Sets the focus in the `Editor` within the cell.
    public func setFocus() {
        editor.setFocus()
    }

    /// Removes the focus from the `Editor` within the cell.
    public func removeFocus() {
        editor.resignFocus()
    }

    /// Applies the given style to the cell
    /// - Parameter style: Style to apply
    public func applyStyle(_ style: GridCellStyle) {
        contentView.layer.borderColor = style.borderStyle?.color.cgColor ?? gridStyle.borderColor.cgColor
        contentView.layer.borderWidth = style.borderStyle?.width ?? gridStyle.borderWidth

        if let font = style.font {
            editor.font = font
            editor.addAttributes([.font: font], at: editor.attributedText.fullRange)
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
        ])

        NSLayoutConstraint.activate([
            widthAnchorConstraint,
            heightAnchorConstraint
        ])
    }

    func hideEditor() {
        editor.removeFromSuperview()
    }

    func showEditor() {
        contentView.addSubview(editor)
    }
}

extension GridCell: BoundsObserving {
    public func didChangeBounds(_ bounds: CGRect, oldBounds: CGRect) {
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

    public func editor(_ editor: EditorView, shouldHandle key: EditorKey, at range: NSRange, handled: inout Bool) {

    }

    public func editor(_ editor: EditorView, didChangeTextAt range: NSRange) {

    }

    public func editor(_ editor: EditorView, didExecuteProcessors processors: [TextProcessing], at range: NSRange) {

    }

    public func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize) {

    }

    public func editor(_ editor: EditorView, didLayout content: NSAttributedString) {

    }

    public func editor(_ editor: EditorView, willSetAttributedText attributedText: NSAttributedString) {

    }

    public func editor(_ editor: EditorView, didSetAttributedText attributedText: NSAttributedString) {

    }

    public func editor(_ editor: EditorView, isReady: Bool) {

    }

    public func editor(_ editor: EditorView, didChangeEditable isEditable: Bool) {

    }


}

extension GridCell: Equatable {
    public static func ==(lhs: GridCell, rhs: GridCell) -> Bool {
        return lhs.id == rhs.id
    }
}
