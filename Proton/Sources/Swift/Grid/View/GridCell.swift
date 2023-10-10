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
import OSLog

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
    public typealias EditorInitializer = () -> EditorView

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
    private let editorInitializer: EditorInitializer

    var isRunningTests: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
#else
        return false
#endif
    }

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

    private(set) var editorSetupComplete = false
    private var _editor: EditorView?
    /// Editor within the cell
    public var editor: EditorView {
        assertEditorSetupCompleted()

        if let _editor {
            return _editor
        }
        let editor = editorInitializer()
        _editor = editor
        return editor
    }

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
    public let style: GridCellStyle
    public let ignoresOptimizedInit: Bool

    let widthAnchorConstraint: NSLayoutConstraint
    let heightAnchorConstraint: NSLayoutConstraint

    var topAnchorConstraint: NSLayoutConstraint!
    var leadingAnchorConstraint: NSLayoutConstraint!

    weak var delegate: GridCellDelegate?

    let initialHeight: CGFloat


    /// Initializes the cell
    /// - Parameters:
    ///   - editorInitializer: Closure for setting up the `EditorView` within the cell. I
    ///   - rowSpan: Array of row indexes the cells spans. For e.g. a cell with first two rows as merged, will have a value of [0, 1] denoting 0th and 1st index.
    ///   - columnSpan: Array of column indexes the cells spans. For e.g. a cell with first two columns as merged, will have a value of [0, 1] denoting 0th and 1st index.
    ///   - initialHeight: Initial height of the cell. This will be updated based on size of editor content on load,
    ///   - style: Visual style of the cell
    ///   - gridStyle: Visual style for grid containing cell border color and width
    ///   - ignoresOptimizedInit: Ignores optimization to initialize editor within the cell. With optimization, the editor is not initialized until the cell is ready to be rendered on the UI thereby not incurring any overheads when creating
    ///   attributedText containing a `GridView` in an attachment. Defaults to `false`.
    /// - Important:
    /// Creating a `GridView` with 100s of cells can result in slow performance when creating an attributed string containing the GridView attachment. Using the closure defers the creation until the view is ready to be rendered in the UI.
    /// It is recommended to setup all the parts of editor in closure where possible, or wait until after the GridView is rendered. In case, editor must be initialized before the rendering is complete and it is not possible to configure an aspect within the closure itself,
    /// `setupEditor()` may be invoked. Use of `setupEditor()` is discouraged.
    public init(
        editorInitializer: @escaping EditorInitializer,
        rowSpan: [Int],
        columnSpan: [Int],
        initialHeight: CGFloat = 40,
        style: GridCellStyle = .init(),
        gridStyle: GridStyle = .default,
        ignoresOptimizedInit: Bool = false)
    {
        self.editorInitializer = editorInitializer
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.gridStyle = gridStyle
        self.style = style
        self.initialHeight = initialHeight
        // Ensure Editor frame is .zero as otherwise it conflicts with some layout calculations
        //        self.editor.frame = .zero
        self.contentView.layoutMargins = .zero
        self.ignoresOptimizedInit = ignoresOptimizedInit

        widthAnchorConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = contentView.heightAnchor.constraint(equalToConstant: 0)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contentViewTapped))
        contentView.addGestureRecognizer(tapGestureRecognizer)

        self.selectionView = SelectionView { [weak self] in
            self?.isSelected = false
        }

        setup()
    }

    public convenience init(rowSpan: [Int], columnSpan: [Int], initialHeight: CGFloat = 40, style: GridCellStyle = .init(), gridStyle: GridStyle = .default, ignoresOptimizedInit: Bool = true) {
        self.init(
            editorInitializer: { EditorView(allowAutogrowing: false) },
            rowSpan: rowSpan,
            columnSpan: columnSpan,
            initialHeight: initialHeight,
            style: style,
            gridStyle: gridStyle,
            ignoresOptimizedInit: ignoresOptimizedInit
        )
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

    private func assertEditorSetupCompleted() {
        guard editorSetupComplete == false,
              ignoresOptimizedInit == false else {
            return
        }

        guard !isRunningTests else {
            if #available(iOSApplicationExtension 14.0, *) {
            Logger.gridView.info(
                """
                Editor setup is not complete as Grid containing cell is not in a window.
                Set `ignoresOptimizedInit` to true in GridConfig or GridCell to suppress this message.
                """
            )}
            return
        }

        assertionFailure(
          """
          Editor setup is not complete as Grid containing cell is not in a window.
          Refer to initialiser documentation for additional details.
          """)
    }

    @objc
    private func contentViewTapped() {
        editor.becomeFirstResponder()
    }

    private func setup() {
        NSLayoutConstraint.activate([
            widthAnchorConstraint,
            heightAnchorConstraint
        ])
    }

    func setupEditor() {
        editorSetupComplete = true
        applyStyle(style)
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
}

extension GridCell: Equatable {
    public static func ==(lhs: GridCell, rhs: GridCell) -> Bool {
        return lhs.id == rhs.id
    }
}
