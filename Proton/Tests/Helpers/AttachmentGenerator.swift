//
//  AttachmentGenerator.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 10/4/24.
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
import Proton

struct AttachmentGenerator {
    private init() { }

    static func makeTableViewAttachment(
        id: Int,
        numRows: Int,
        numColumns: Int,
        columnConfig: GridColumnConfiguration? = nil,
        rowConfig: GridRowConfiguration? = nil
    ) -> TableViewAttachment {
        let columnConfiguration = columnConfig ?? GridColumnConfiguration(width: .fixed(100))
        let rowConfiguration = rowConfig ?? GridRowConfiguration(initialHeight: 50)

        let config = GridConfiguration(
            columnsConfiguration: [GridColumnConfiguration](repeating: columnConfiguration, count: numColumns),
            rowsConfiguration: [GridRowConfiguration](repeating: rowConfiguration, count: numRows)
        )

        var cells = [TableCell]()
        for row in 0..<numRows {
            for col in 0..<numColumns {
                let editorInit = {
                    let editor = EditorView(allowAutogrowing: false)
                    editor.attributedText = NSAttributedString(string: "Table \(id) {\(row), \(col)} Text in cell")
                    return editor
                }
                let cell = TableCell(
                    rowSpan: [row],
                    columnSpan: [col],
                    initialHeight: 20,
                    editorInitializer: editorInit
                )
                cells.append(cell)
            }
        }

        let attachment = TableViewAttachment(config: config, cells: cells)
        return attachment
    }
}
