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

    public let name = CommandName("createGridViewCommand")
    weak var delegate: GridViewDelegate?
    var text = NSMutableAttributedString()

    public init(delegate: GridViewDelegate) {
        self.delegate = delegate

        text.append(NSAttributedString(string: "Text before Grid"))
        text.append(makeGridViewAttachment(numRows: 5, numColumns: 5).string)
        text.append(NSAttributedString(string: "Text before Grid"))
    }

    public func execute(on editor: EditorView) {
        editor.attributedText = text
    }

    private func makeGridViewAttachment(numRows: Int, numColumns: Int) -> GridViewAttachment {
        let config = GridConfiguration(columnsConfiguration: [GridColumnConfiguration](repeating: GridColumnConfiguration(width: .fixed(100)), count: numColumns),
                                       rowsConfiguration: [GridRowConfiguration](repeating: GridRowConfiguration(initialHeight: 40), count: numRows))

        var cells = [GridCell]()
        for row in 0..<numRows {
            for col in 0..<numColumns {
                let cell = GridCell(rowSpan: [row], columnSpan: [col], initialHeight: 20)
                cell.editor.isEditable = false
                cell.editor.attributedText = NSAttributedString(string: "{\(row), \(col)} Text in cell")
                cells.append(cell)
            }
        }

        return GridViewAttachment(config: config, cells: cells)
    }
}
