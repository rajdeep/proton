//
//  CommandsExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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

import Proton

class EditorCommandButton: UIButton {
    let command: EditorCommand

    let highlightOnTouch: Bool

    init(command: EditorCommand, highlightOnTouch: Bool) {
        self.command = command
        self.highlightOnTouch = highlightOnTouch
        super.init(frame: .zero)
        titleLabel?.font = UIButton(type: .system).titleLabel?.font
        isSelected = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            setTitleColor(isSelected ? .white : .systemBlue, for: .normal)
            backgroundColor = isSelected ? .systemBlue : .systemBackground
        }
    }
}

class CommandsExampleViewController: ExamplesBaseViewController {

    let commandExecutor = EditorCommandExecutor()
    var buttons = [UIButton]()
    let stackView = UIStackView()

    var encodedContents: JSON = ["contents": []]

    var commands: [(title: String, command: EditorCommand, highlightOnTouch: Bool)] = [
        (title: "Panel", command: PanelCommand(), highlightOnTouch: false),
        (title: "Expand", command: ExpandCommand(), highlightOnTouch: false),
        (title: "List", command: ListCommand(), highlightOnTouch: false),
        (title: "Bold", command: BoldCommand(), highlightOnTouch: true),
        (title: "Italics", command: ItalicsCommand(), highlightOnTouch: true),
        (title: "TextBlock", command: TextBlockCommand(), highlightOnTouch: false),
    ]

    let editorButtons: [(title: String, selector: Selector)] = [
        (title: "Merge", selector: #selector(mergeCells(sender:))),
        (title: "Split", selector: #selector(splitCells(sender:))),
        (title: "Encode", selector: #selector(encodeContents(sender:))),
        (title: "Decode", selector: #selector(decodeContents(sender:))),
        (title: "Sample", selector: #selector(loadSample(sender:))),
    ]

    let listFormattingProvider = ListFormattingProvider()

    var allButtons: [UIButton] {
        stackView.subviews.compactMap({ $0 as? UIButton})
    }

    var mergeButton: UIButton? {
        allButtons.first(where: { $0.titleLabel?.text == "Merge" })
    }

    var splitButton: UIButton? {
        allButtons.first(where: { $0.titleLabel?.text == "Split" })
    }

    override func setup() {
        super.setup()

        commands.insert((title: "Table", command: CreateGridViewCommand(delegate: self), highlightOnTouch: false), at: 2)

        buttons.first(where: { $0.titleLabel?.text == "Merge" })?.isSelected = false

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0

        editor.listFormattingProvider = listFormattingProvider

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        editor.delegate = self
        editor.asyncAttachmentRenderingDelegate = self
        EditorViewContext.shared.delegate = self

        editor.registerProcessor(ListTextProcessor())
//        editor.paragraphStyle.paragraphSpacingBefore = 20

        self.buttons = makeCommandButtons()
        for button in buttons {
            stackView.addArrangedSubview(button)
        }

        let editorButtons = makeEditorButtons()
        for button in editorButtons {
            stackView.addArrangedSubview(button)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),

            scrollView.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: 10),

            stackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            editor.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            editor.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
        ])

        mergeButton?.isEnabled = false
        splitButton?.isEnabled = false
    }

    func makeCommandButtons() -> [UIButton] {
        var buttons = [UIButton]()
        for (title, command, highlightOnTouch) in commands {
            let button = EditorCommandButton(command: command, highlightOnTouch: highlightOnTouch)
            button.setTitle(title, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(runCommand(sender:)), for: .touchUpInside)

            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 5.0

            NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 70)])
            buttons.append(button)
        }
        return buttons
    }

    func makeEditorButtons() -> [UIButton] {
        var buttons = [UIButton]()
        for editorButton in editorButtons {
            let button = UIButton(type: .system)
            button.tintColor = .systemBlue
            button.setTitle(editorButton.title, for: .normal)
            button.backgroundColor = .systemBackground
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: editorButton.selector, for: .touchUpInside)

            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 5.0

            NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 70)])
            buttons.append(button)
        }
        return buttons
    }

    @objc
    func runCommand(sender: EditorCommandButton) {
        if sender.highlightOnTouch {
            sender.isSelected.toggle()
        }
        if sender.titleLabel?.text == "Encode" {
            sender.command.execute(on: editor)
            return
        } else if sender.titleLabel?.text == "List" {
            if let command = sender.command as? ListCommand,
                let editor = editor.editorViewContext.activeEditorView {
                var attributeValue: String? = "listItemValue"
                if editor.contentLength > 0,
                    editor.attributedText.attribute(.listItem, at: min(editor.contentLength - 1, editor.selectedRange.location), effectiveRange: nil) != nil {
                    attributeValue = nil
                }
                command.execute(on: editor, attributeValue: attributeValue)
                return
            }
        }
        commandExecutor.execute(sender.command)
    }

    var selectedCells: [GridCell]? = nil
    var selectedGrid: GridView? = nil

    @objc
    func mergeCells(sender: UIButton) {
        if let cells = selectedCells {
            selectedGrid?.merge(cells: cells)
        }
        selectedCells = nil
        selectedGrid = nil
    }

    @objc
    func splitCells(sender: UIButton) {
        if selectedCells?.count == 1,
           let cell = selectedCells?.first,
           cell.isSplittable {
            selectedGrid?.split(cell: cell)
        }
        selectedCells = nil
        selectedGrid = nil
    }

    @objc
    func encodeContents(sender: UIButton) {
        let value = editor.transformContents(using: JSONEncoder())
        let data = try! JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
        let jsonString = String(data: data, encoding: .utf8)!
        self.encodedContents = ["contents": value]

        let printableContents = """
            { "contents":  \(jsonString) }
        """

        print(printableContents)

        editor.attributedText = NSAttributedString()
    }

    @objc
    func decodeContents(sender: UIButton) {
        let text = try? EditorContentJSONDecoder(
            ).decode(mode: .editor,
            maxSize: editor.frame.size,
            value: encodedContents,
            context: nil)
        self.editor.attributedText = text ?? NSAttributedString(string: "<Error decoding contents>",
                                                                attributes: [.foregroundColor: UIColor.red])
    }

    @objc
    func loadSample(sender: UIButton) {
        guard let contents = Bundle.main.jsonFromFile("SampleDoc") else {
            return
        }

        let text = try? EditorContentJSONDecoder().decode(mode: .editor, maxSize: editor.frame.size, value: contents, context: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.editor.attributedText = text ?? NSAttributedString(string: "<Error decoding contents>",
                                                                    attributes: [.foregroundColor: UIColor.red])
        }
    }

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.down")!, for: .normal)

        button.layer.cornerRadius = 4
        button.layer.backgroundColor = UIColor.systemGray6.cgColor
        button.layer.shadowColor = UIColor.systemGray2.cgColor
        button.layer.shadowOffset = CGSize(width: -2, height: -2)
        return button
    }()
    
}

extension CommandsExampleViewController: EditorViewDelegate {
    func editor(_ editor: EditorView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key: Any], contentType: EditorContent.Name) {
        guard let font = attributes[.font] as? UIFont else { return }

        buttons.first(where: { $0.titleLabel?.text == "Bold" })?.isSelected = font.isBold
        buttons.first(where: { $0.titleLabel?.text == "Italics" })?.isSelected = font.isItalics
    }

    func editor(_ editor: EditorView, didReceiveFocusAt range: NSRange) {
        print("Focussed: `\(editor.contentName?.rawValue ?? "<root editor>")` at depth: \(editor.nestingLevel)")
    }

    func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize) {
//        print("Height changed from \(previousSize.height) to \(currentSize.height)")
    }

    func editor(_ editor: EditorView, didTapAtLocation location: CGPoint, characterRange: NSRange?) {
        guard let characterRange = characterRange else {
            print("Tapped at \(location) with no available range")
            return
        }

        print("Tapped at \(location) with text: \(editor.attributedText.attributedSubstring(from: characterRange))")
    }

    func editor(_ editor: EditorView, didReceiveKey key: EditorKey, at range: NSRange) {
        print("Key: \(key)")
    }

    func editor(_ editor: EditorView, shouldHandle key: EditorKey, modifierFlags: UIKeyModifierFlags, at range: NSRange, handled: inout Bool) {
        print("Key: \(key)")
    }
}

extension CommandsExampleViewController: GridViewDelegate {
    func gridView(_ gridView: Proton.GridView, selectionHandleFor cell: Proton.GridCell) -> UIButton? {
        nil
    }
    
    func gridView(_ gridView: GridView, didReceiveKey key: EditorKey, at range: NSRange, in cell: GridCell) { }

    func gridView(_ gridView: GridView, didLayoutCell cell: GridCell) { }

    func gridView(_ gridView: GridView, didReceiveFocusAt range: NSRange, in cell: GridCell) {
        let columnCount = gridView.numberOfColumns
        let columnActions = [
            UIAction(title: "Add column right", image: UIImage(systemName: "arrow.right"),
                     handler: { (_) in
                         let result = gridView.insertColumn(at: cell.columnSpan.max()! + 1, configuration: GridColumnConfiguration(width: .fixed(100)))
                         if case let Result.failure(error) = result {
                             print("Failed to insert: \(error)")
                         }
                     }),
//            UIAction(title: "Add column left", image: UIImage(systemName: "arrow.left"),
//                     handler: { (_) in
//                         gridView.insertColumn(at: cell.columnSpan.min()!, configuration: GridColumnConfiguration(dimension: .fixed(100)))
//                     }),
//            UIAction(title: "Delete Column", image: UIImage(systemName: "trash"), attributes: columnCount > 1 ? .destructive : .disabled, handler: { (_) in
//                gridView.deleteColumn(at: cell.columnSpan.max()!)
//            }),
//            UIAction(title: "Freeze Columns", image: UIImage(systemName: "arrow.up"), handler: { (_) in
//                gridView.freezeColumns(upTo: cell.columnSpan.max()!)
//            }),
//
//            UIAction(title: "Unfreeze Columns", image: UIImage(systemName: "trash"), attributes: gridView.containsFrozenColumns ? [] : .disabled, handler: { (_) in
//                gridView.unfreezeColumns()
//            })
        ]

        let rowActions = [
            UIAction(title: "Add row above", image: UIImage(systemName: "arrow.up"), handler: { (_) in
                gridView.insertRow(at: cell.rowSpan.min()!, configuration: GridRowConfiguration(initialHeight: 40))
            }),
            UIAction(title: "Add row below", image: UIImage(systemName: "arrow.down"), handler: { (_) in
                gridView.insertRow(at: cell.rowSpan.max()! + 1, configuration: GridRowConfiguration(initialHeight: 40))
            }),
            UIAction(title: "Delete Row", image: UIImage(systemName: "trash"), attributes: columnCount > 1 ? .destructive : .disabled, handler: { (_) in
                gridView.deleteRow(at: cell.rowSpan.max()!)
            })
//            UIAction(title: "Freeze Rows", image: UIImage(systemName: "arrow.up"), handler: { (_) in
//                gridView.freezeRows(upTo: cell.rowSpan.max()!)
//                for i in 0...cell.rowSpan.max()! {
//                    if i%2 == 0 {
//                        gridView.applyStyle(GridCellStyle(backgroundColor: .systemGray, textColor: .white, font: UIFont.boldSystemFont(ofSize: 17), borderStyle: GridCellStyle.BorderStyle(color: .white, width: 1)), toRow: i)
//                    } else {
//                        gridView.applyStyle(GridCellStyle(backgroundColor: .lightGray, textColor: .black, font: UIFont.boldSystemFont(ofSize: 17), borderStyle: GridCellStyle.BorderStyle(color: .white, width: 1)), toRow: i)
//                    }
//                }
//            }),
//
//            UIAction(title: "Unfreeze Rows", image: UIImage(systemName: "trash"), attributes: gridView.containsFrozenRows ? [] : .disabled, handler: { (_) in
//                if let index = gridView.frozenRowMaxIndex {
//                    gridView.unfreezeRows()
//                    for i in 0...index {
//                        gridView.applyStyle(GridCellStyle(backgroundColor: .white, textColor: .black, font: UIFont.systemFont(ofSize: 17)), toRow: i)
//                    }
//                }
//            })
        ]

        let cellActions = [
            UIAction(title: "Color cell", image: UIImage(systemName: "paintpalette"), handler: { (_) in
                let style = GridCellStyle(backgroundColor: .systemGray3, textColor: .red, font: UIFont.boldSystemFont(ofSize: 14))
                cell.applyStyle(style)
            }),
        ]

        let columnMenu = UIMenu(title: "Column Options", options: .displayInline, children: columnActions)
        let rowMenu = UIMenu(title: "Row Options", options: .displayInline, children: rowActions)
        let cellMenu = UIMenu(title: "Cell Options", options: .displayInline, children: cellActions)

        let menu = UIMenu(title: "Cell Options", children: [columnMenu, rowMenu, cellMenu])

        let button = actionButton
        if #available(iOS 14.0, *) {
            button.menu = menu
            button.showsMenuAsPrimaryAction = true
        }

        cell.contentView.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -5),
            button.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 5),
            button.widthAnchor.constraint(equalToConstant: 20),
            button.heightAnchor.constraint(equalTo: button.widthAnchor),
        ])
    }

    func gridView(_ gridView: GridView, didLoseFocusFrom range: NSRange, in cell: GridCell) {
        actionButton.removeFromSuperview()
    }

    func gridView(_ gridView: GridView, didTapAtLocation location: CGPoint, characterRange: NSRange?, in cell: GridCell) {

    }

    func gridView(_ gridView: GridView, didChangeSelectionAt range: NSRange, attributes: [NSAttributedString.Key : Any], contentType: EditorContent.Name, in cell: GridCell) {

    }

    func gridView(_ gridView: GridView, didChangeBounds bounds: CGRect, in cell: GridCell) {

    }

    func gridView(_ gridView: GridView, didSelectCells cells: [GridCell]) {
        selectedGrid = gridView
        selectedCells = cells
        mergeButton?.isEnabled = gridView.isCellSelectionMergeable(cells)

        if cells.count == 1, cells[0].isSplittable {
            splitButton?.isEnabled = true
        } else {
            splitButton?.isEnabled = false
        }
    }

    func gridView(_ gridView: GridView, didUnselectCells cells: [GridCell]) {

    }

    func gridView(_ gridView: GridView, shouldChangeColumnWidth proposedWidth: CGFloat, for columnIndex: Int) -> Bool {
        return proposedWidth > 50
    }
}

class ListFormattingProvider: EditorListFormattingProvider {
    let listLineFormatting: LineFormatting = LineFormatting(indentation: 25, spacingBefore: 0)
    let sequenceGenerators: [SequenceGenerator] =
        [NumericSequenceGenerator(),
         DiamondBulletSequenceGenerator(),
         SquareBulletSequenceGenerator()]

    func listLineMarkerFor(editor: EditorView, index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker {
        let sequenceGenerator = self.sequenceGenerators[(level - 1) % self.sequenceGenerators.count]
        return sequenceGenerator.value(at: index)
    }
}

extension CommandsExampleViewController: AsyncAttachmentRenderingDelegate {
    var prioritizedViewport: CGRect? { nil }

    func shouldRenderAsync(attachment: Proton.Attachment) -> Bool {
        attachment is GridViewAttachment
    }

    func didRenderAttachment(_ attachment: Proton.Attachment, in editor: Proton.EditorView) {
        print("Render: \(attachment.id) : \(attachment.contentSize)")
    }

    func didCompleteRenderingViewport(_ viewport: CGRect, in editor: EditorView) {
        print("Rendered viewport: \(viewport)")
    }
}
