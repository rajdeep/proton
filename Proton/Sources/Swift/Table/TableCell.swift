//
//  TableCell.swift
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
import OSLog


protocol TableCellDelegate: AnyObject {
    func cell(_ cell: TableCell, didAddContentView view: TableCellContentView)
    func cell(_ cell: TableCell, didRemoveContentView view: TableCellContentView?)

    func cell(_ cell: TableCell, didChangeBounds bounds: CGRect)
    func cell(_ cell: TableCell, didReceiveFocusAt range: NSRange)
    func cell(_ cell: TableCell, didLoseFocusFrom range: NSRange)
    func cell(_ cell: TableCell, didTapAtLocation location: CGPoint, characterRange: NSRange?)
    func cell(_ cell: TableCell, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name)
    func cell(_ cell: TableCell, didReceiveKey key: EditorKey, at range: NSRange)
    func cell(_ cell: TableCell, didChangeSelected isSelected: Bool)
    func cell(_ cell: TableCell, didChangeBackgroundColor color: UIColor?, oldColor: UIColor?)
}

public class TableCell {

    public typealias EditorInitializer = () -> EditorView

    var id: String {
        "{\(rowSpan),\(columnSpan)}"
    }

    /// Additional attributes that can be stored on Cell to identify various aspects like Header, Numbered etc.
    public var additionalAttributes: [String: Any] = [:]

    /// Row indexes spanned by the cell. In case of a merged cell, this will contain all the rows= indexes which are merged.
    public internal(set) var rowSpan: [Int]
    /// Column indexes spanned by the cell. In case of a merged cell, this will contain all the column indexes which are merged.
    public internal(set) var columnSpan: [Int]

    /// Frame of the cell within `GridView`
    public internal(set) var frame: CGRect = .zero

    public var backgroundColor: UIColor? = nil {
        didSet {
            contentView?.backgroundColor = backgroundColor
        }
    }

    let editorInitializer: EditorInitializer

    /// Controls if the cell can be selected or not.
    public var isSelectable: Bool {
        get { contentView?.isSelectable ?? false }
        set { contentView?.isSelectable = newValue }
    }

    public var isSelected: Bool {
        get { contentView?.isSelected ?? false }
        set { contentView?.isSelected = newValue }
    }

    /// Denotes if the cell can be split i.e. is a merged cell.
    public var isSplittable: Bool {
        rowSpan.count > 1 || columnSpan.count > 1
    }

    /// Content size of the cell
    public var contentSize: CGSize {
        contentView?.contentSize ?? .zero
    }

    /// Content view for the cell
    public private(set) var contentView: TableCellContentView?

    public let gridStyle: GridStyle
    public let style: GridCellStyle

    weak var delegate: TableCellDelegate?

    let initialHeight: CGFloat

    /// Initializes the cell
    /// - Parameters:
    ///   - rowSpan: Array of row indexes the cells spans. For e.g. a cell with first two rows as merged, will have a value of [0, 1] denoting 0th and 1st index.
    ///   - columnSpan: Array of column indexes the cells spans. For e.g. a cell with first two columns as merged, will have a value of [0, 1] denoting 0th and 1st index.
    ///   - initialHeight: Initial height of the cell. This will be updated based on size of editor content on load,
    ///   - style: Visual style of the cell
    ///   - gridStyle: Visual style for grid containing cell border color and width
    ///   - ignoresOptimizedInit: Ignores optimization to initialize editor within the cell. With optimization, the editor is not initialized until the cell is ready to be rendered on the UI thereby not incurring any overheads when creating
    ///   attributedText containing a `GridView` in an attachment. Defaults to `false`.
    ///   - editorInitializer: Closure for setting up the `EditorView` within the cell.
    /// - Important:
    /// Creating a `GridView` with 100s of cells can result in slow performance when creating an attributed string containing the GridView attachment. Using the closure defers the creation until the view is ready to be rendered in the UI.
    /// It is recommended to setup all the parts of editor in closure where possible, or wait until after the GridView is rendered. In case, editor must be initialized before the rendering is complete and it is not possible to configure an aspect within the closure itself,
    /// `setupEditor()` may be invoked. Use of `setupEditor()` is discouraged.
    required public init(rowSpan: [Int],
                columnSpan: [Int],
                initialHeight: CGFloat = 40,
                style: GridCellStyle = .init(),
                gridStyle: GridStyle = .default,
                editorInitializer: EditorInitializer? = nil) {
        self.editorInitializer = editorInitializer ?? { EditorView(allowAutogrowing: false) }
        self.rowSpan = rowSpan
        self.columnSpan = columnSpan
        self.gridStyle = gridStyle
        self.style = style
        self.initialHeight = initialHeight
    }

    /// Sets the focus in the `Editor` within the cell.
    public func setFocus() {
        contentView?.setFocus()
    }

    /// Removes the focus from the `Editor` within the cell.
    public func removeFocus() {
        contentView?.removeFocus()
    }

    func hideEditor() {
        contentView?.hideEditor()
    }

    func showEditor() {
        contentView?.showEditor()
    }

    func removeContentView() {
        delegate?.cell(self, didRemoveContentView: contentView)
        contentView = nil
    }

    func updateBackgroundColorFromParent(color: UIColor?, oldColor: UIColor?) {
        // check for same color is required. In absence of that, the rendering causes
        // collapsed cells to still show text even though cell is collapsed
        guard backgroundColor == oldColor, backgroundColor != color else { return }
        backgroundColor = color
    }

    func addContentView(_ contentView: TableCellContentView) {
        self.contentView = contentView
        delegate?.cell(self, didAddContentView: contentView)
    }
}

extension TableCell: Equatable {
    public static func ==(lhs: TableCell, rhs: TableCell) -> Bool {
        return lhs.id == rhs.id
    }
}

extension TableCell: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
