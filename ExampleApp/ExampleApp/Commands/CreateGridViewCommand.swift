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
        timeEvent(label: "Create")
        for i in 1..<2 {
            text.append(makeGridViewAttachment(id: i, numRows: 25, numColumns: 5).string)
//            text.append(makePanelAttachment(id: i).string)
            text.append(NSAttributedString(string: "\ntest middle\n"))
        }

        text.append(NSAttributedString(string: "Text After Grid"))
    }

    public func execute(on editor: EditorView) {
        timeEvent(label: "Render")
        editor.attributedText = text
    }

    private func makePanelAttachment(id: Int) -> PanelAttachment {
        let attachment = PanelAttachment(frame: .zero)
        attachment.selectBeforeDelete = true
        let panel = attachment.view
        panel.editor.attributedText = NSAttributedString(string: "Panel \(id) - Attachment id: \(attachment.id)")
        return attachment
    }

    private func makeGridViewAttachment(id: Int, numRows: Int, numColumns: Int) -> GridViewAttachment {
        let config = GridConfiguration(columnsConfiguration: [GridColumnConfiguration](repeating: GridColumnConfiguration(width: .fixed(100)), count: numColumns),
                                       rowsConfiguration: [GridRowConfiguration](repeating: GridRowConfiguration(initialHeight: 40), count: numRows))

        var cells = [GridCell]()
        for row in 0..<numRows {
            for col in 0..<numColumns {
                let editorInit = {
                    let editor = EditorView(allowAutogrowing: false)
                    editor.attributedText = NSAttributedString(string: "Table \(id) {\(row), \(col)} Text in cell")
                    return editor
                }
                let cell = GridCell(rowSpan: [row], columnSpan: [col], initialHeight: 20, editorInitializer: editorInit)
                cells.append(cell)
            }
        }

        let attachment = GridViewAttachment(config: config, cells: cells)
        attachment.view.delegate = delegate
        attachment.view.setColumnResizing(true)
        return attachment
    }

    func timeEvent(label: String) {
        let start = DispatchTime.now()
        DispatchQueue.main.async {
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            print("\(label): \(timeInterval) seconds")
        }
    }
}
