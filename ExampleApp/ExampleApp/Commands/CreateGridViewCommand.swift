//
//  CreateGridViewCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
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
import Proton

/// Editor command that inserts a GridView in the given range
public class CreateGridViewCommand: EditorCommand {

    var text = NSMutableAttributedString()
    public let name = CommandName("createGridViewCommand")
    weak var delegate: GridViewDelegate?
    public init(delegate: GridViewDelegate) {
        self.delegate = delegate

        text.append(NSAttributedString(string: "lkahjsd ljaksljd jaskld \nakljshd ahs dhkjsaj \nakjhds kjhas"))
//        text.append(makeGridViewAttachment(numRows: 50, numColumns: 20).string)
        for i in 0..<5 {
            let attachment = PanelAttachment(frame: CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
            attachment.view.editor.maxHeight = .infinite
            attachment.view.editor.attributedText = NSAttributedString(string: "*\(i)* kj jhjk hkj jkjkjkh jh jkh jk hjkhjk k hjkhkj hkjh kj")
            text.append(attachment.string)
            text.append(NSAttributedString(string: "\n"))
        }
//        text.append(makeGridViewAttachment(numRows: 50, numColumns: 20).string)
    }

    public func execute(on editor: EditorView) {
//        let config = GridConfiguration(
//            columnsConfiguration: [
////                GridColumnConfiguration(dimension: .fixed(150)),
//                GridColumnConfiguration(width: .fractional(0.25)),
//                GridColumnConfiguration(width: .fractional(0.25)),
//                GridColumnConfiguration(width: .fractional(0.25)),
//                GridColumnConfiguration(width: .fractional(0.25)),
//                GridColumnConfiguration(width: .fractional(0.25)),
//                GridColumnConfiguration(width: .fractional(0.25)),
//            ],
//            rowsConfiguration: [
//                GridRowConfiguration(initialHeight: 40),
//                GridRowConfiguration(initialHeight: 80),
//                GridRowConfiguration(initialHeight: 120),
//                GridRowConfiguration(initialHeight: 40),
//                GridRowConfiguration(initialHeight: 80),
//                GridRowConfiguration(initialHeight: 120),
//            ])
//
//        let attachment = GridViewAttachment(config: config)
//        attachment.selectBeforeDelete = true
//        attachment.view.delegate = delegate
////        attachment.view.setColumnResizing(true)
//        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
//        editor.maxHeight = .infinite
        editor.attributedText = text
//        editor.setNeedsLayout()
//        editor.superview?.layoutIfNeeded()
    }

    private func makeGridViewAttachment(numRows: Int, numColumns: Int) -> GridViewAttachment {
        let config = GridConfiguration(
            columnsConfiguration: [GridColumnConfiguration](repeating: GridColumnConfiguration(width: .fixed(100)), count: numColumns),
            rowsConfiguration: [GridRowConfiguration](repeating: GridRowConfiguration(initialHeight: 40), count: numRows))

        var cells = [GridCell]()
        for row in 0..<numRows {
            for col in 0..<numColumns {
                let cell = GridCell(rowSpan: [row], columnSpan: [col], initialHeight: 20)
                cell.editor.isEditable = false
                cell.editor.attributedText = NSAttributedString(string: "{\(row), \(col)} ashd asjhd asjdl jasjdhlasjd lkjasldjlkasj dljaslkdj lsaj lkjahsd khasjkh dk")
                cells.append(cell)
            }
        }

        return GridViewAttachment(config: config, cells: cells)
    }
}
