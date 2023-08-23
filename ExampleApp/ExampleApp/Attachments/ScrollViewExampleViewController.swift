//
//  ScrollViewExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 10/8/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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

class ScrollViewExampleViewController: ExamplesBaseViewController {

    let scrollView = UIScrollView()
    let contentView = UIStackView()
    let headerLabel = UILabel()

    override func setup() {
        super.setup()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)

        scrollView.addSubview(contentView)
        contentView.addArrangedSubview(headerLabel)
//        contentView.addSubview(editor)

        headerLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam vulputate rhoncus ante, at condimentum ante tristique eget. Vivamus hendrerit hendrerit ante. Phasellus id libero congue, fringilla mi eget, dignissim erat. Maecenas imperdiet massa nec nunc posuere blandit. Interdum et malesuada fames ac ante ipsum primis in faucibus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus."
        headerLabel.numberOfLines = 0
        headerLabel.lineBreakMode = .byWordWrapping
        headerLabel.sizeToFit()

        contentView.addArrangedSubview(editor)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .cyan
        contentView.distribution = .fill
//        contentView.spacing = 16
        contentView.axis = .vertical

        let contentMargin = 0.0
        let sa = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: contentMargin),
            editor.leadingAnchor.constraint(equalTo: sa.leadingAnchor, constant: contentMargin),
            editor.trailingAnchor.constraint(equalTo: sa.trailingAnchor, constant: -contentMargin),
            editor.bottomAnchor.constraint(equalTo: sa.bottomAnchor, constant: -contentMargin)
        ])

        scrollView.layer.borderColor = UIColor.label.cgColor
        scrollView.layer.borderWidth = 1.0
        editor.isScrollEnabled = false
        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0
//        editor.delegate = self
        editor.isEditable = false

        let button = UIButton(type: .system)
        button.setTitle("Insert attachment", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(insertAttachment(sender:)), for: .touchUpInside)

        view.addSubview(button)
        let contentLayoutGuide = scrollView.contentLayoutGuide

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//
            scrollView.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
//            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,constant: -20),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            editor.topAnchor.constraint(equalTo: headerLabel.bottomAnchor),
            editor.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            editor.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    @objc
    func insertAttachment(sender: UIButton) {
       setupText()
    }

    func setupText() {
        let grid = makeGridViewAttachment(id: "1", numRows: 10, numColumns: 5)
        let grid2 = makeGridViewAttachment(id: "2", numRows: 10, numColumns: 5)

        var text = NSMutableAttributedString()
        text.append(grid.string)

        for i in 0..<5 {
            text.append(makePanelAttachment(text: NSAttributedString(string: "Panel \(i) The issue started happening after Proton v0.8.8 as it fixed code for isReady to only set isReady to true if window is not nil")).string)
        }

        text.append(NSAttributedString(string: """
        The issue started happening after Proton v0.8.8 as it fixed code for isReady to only set isReady to true if window is not nil. Previously, due to this bug in Proton, Editor code was invoking processInlineComments twice which was somehow hiding this likely bug in iOS. After the fix,  processInlineComments is only invoked once and thus highlights this issue when editor is in read-only mode and annotation to scroll to happens to be in last 2 lines of content.

        The issue is fixed by invoking scrollRectToVisible twice for annotation. It is still better than executing processInlineComments twice. This may be fixed with a future version of iOS after which we may remove the duplicate call.
        """))
//        for i in 11..<13 {
//            text.append(makePanelAttachment(text: NSAttributedString(string: "Panel \(i)")).string)
//        }

        text.append(grid2.string)
//        editor.maxHeight = .infinite
        editor.attributedText = text
    }

    private func makePanelAttachment(text: NSAttributedString) -> Attachment {
        var panel = PanelView()
        panel.backgroundColor = .systemTeal
        panel.textColor = .black
        panel.editor.attributedText = text
        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.isScrollEnabled = false
        return attachment
    }


    private func makeGridViewAttachment(id: String, numRows: Int, numColumns: Int) -> GridViewAttachment {
        let config = GridConfiguration(columnsConfiguration: [GridColumnConfiguration](repeating: GridColumnConfiguration(width: .fixed(100)), count: numColumns),
                                       rowsConfiguration: [GridRowConfiguration](repeating: GridRowConfiguration(initialHeight: 40), count: numRows))

        var cells = [GridCell]()
        for row in 0..<numRows {
            for col in 0..<numColumns {
                let cell = GridCell(rowSpan: [row], columnSpan: [col], initialHeight: 20)
                cell.editor.isEditable = false
                cell.editor.attributedText = NSAttributedString(string: "ID: \(id) {\(row), \(col)} Text in cell")
                cells.append(cell)
            }
        }

        return GridViewAttachment(config: config, cells: cells)
    }
}

//extension ScrollViewExampleViewController: EditorViewDelegate {
//    func editor(_ editor: EditorView, didChangeSize currentSize: CGSize, previousSize: CGSize) {
////        scrollView.layoutIfNeeded()
//    }
//}
