//
//  TableCellContentView.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/4/2024.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
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

public class TableCellContentView: UIView {
    public let editor: EditorView

    private let style: GridCellStyle
    private let gridStyle: GridStyle
    private var selectionView: SelectionView?
    private let initialHeight: CGFloat
    private unowned var containerCell: TableCell

    var delegate: TableCellDelegate? {
        containerCell.delegate
    }

    public var isSelectable: Bool = true

    public override var backgroundColor: UIColor? {
        didSet {
            editor.backgroundColor = backgroundColor
        }
    }

    public override var intrinsicContentSize: CGSize {
        containerCell.frame.size
    }

    public var contentSize: CGSize {
        editor.frame.size
    }
    
    /// Sets the cell selected
    public var isSelected: Bool {
        get { selectionView?.superview != nil }
        set {
            guard isSelectable,
                  newValue != isSelected else { return }
            if newValue {
                selectionView?.addTo(parent: self)
            } else {
                selectionView?.removeFromSuperview()
            }
            self.delegate?.cell(containerCell, didChangeSelected: isSelected)
        }
    }

    init(containerCell: TableCell) {
        self.editor = containerCell.editorInitializer()
        self.initialHeight = containerCell.initialHeight
        self.containerCell = containerCell
        self.style = containerCell.style
        self.gridStyle = containerCell.gridStyle
        super.init(frame: containerCell.frame)

        self.layoutMargins = .zero

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contentViewTapped))
        addGestureRecognizer(tapGestureRecognizer)

        self.selectionView = SelectionView { [weak self] in
            guard let self else { return }
            self.isSelected = false
        }

        setupEditor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEditor() {
        applyStyle(style)
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.boundsObserver = self
        editor.delegate = self

        addSubview(editor)

        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            editor.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: initialHeight)
        ])
    }

    func applyStyle(_ style: GridCellStyle) {
       layer.borderColor = style.borderStyle?.color.cgColor ?? gridStyle.borderColor.cgColor
       layer.borderWidth = style.borderStyle?.width ?? gridStyle.borderWidth

        if let font = style.font {
            editor.font = font
            editor.addAttributes([.font: font], at: editor.attributedText.fullRange)
        }
        if let textColor = style.textColor {
            editor.textColor = textColor
        }
        if let backgroundColor = style.backgroundColor {
            editor.backgroundColor = backgroundColor
            self.backgroundColor = backgroundColor
        }
    }

    func hideEditor() {
        editor.removeFromSuperview()
    }

    func showEditor() {
        addSubview(editor)
    }

    public func setFocus() {
        editor.setFocus()
    }

    /// Removes the focus from the `Editor` within the cell.
    public func removeFocus() {
        editor.resignFocus()
    }

    func removeFromContainerCell() {
        self.removeFromSuperview()
    }

    @objc
    private func contentViewTapped() {
        editor.becomeFirstResponder()
    }
}

extension TableCellContentView: BoundsObserving {
    public func didChangeBounds(_ bounds: CGRect, oldBounds: CGRect) {
        delegate?.cell(containerCell, didChangeBounds: bounds)
    }
}

extension TableCellContentView: EditorViewDelegate {
    public func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        delegate?.cell(containerCell, didReceiveFocusAt: range)
    }

    public func editor(_ editor: EditorView, didLoseFocusFrom range: NSRange) {
        delegate?.cell(containerCell, didLoseFocusFrom: range)
    }

    public func editor(_ editor: EditorView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        delegate?.cell(containerCell, didTapAtLocation: location, characterRange: characterRange)
    }

    public func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name) {
        delegate?.cell(containerCell, didChangeSelectionAt: range, attributes: attributes, contentType: contentType)
    }

    public func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange) {
        delegate?.cell(containerCell, didReceiveKey: key, at: range)
    }

    public func editor(_ editor: EditorView, didChangeBackgroundColor color: UIColor?, oldColor: UIColor?) {
        backgroundColor = color
        delegate?.cell(containerCell, didChangeBackgroundColor: color, oldColor: oldColor)
    }
}
