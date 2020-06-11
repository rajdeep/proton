//
//  PanelCommand.swift
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

class PanelCommand: EditorCommand {
    let name = CommandName("panelCommand")
    func execute(on editor: EditorView) {
        let selectedText = editor.selectedText

        let attachment = PanelAttachment(frame: .zero)
        attachment.selectBeforeDelete = true
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)

        let panel = attachment.view
        panel.editor.maxHeight = 300
        panel.editor.registerProcessors(editor.registeredProcessors)
        panel.editor.listFormattingProvider = editor.listFormattingProvider
        panel.editor.replaceCharacters(in: .zero, with: selectedText)
        panel.editor.selectedRange = panel.editor.textEndRange
    }

    func canExecute(on editor: EditorView) -> Bool {
        let panel = PanelView()
        let minSize = panel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return minSize.width < editor.frame.width
    }
}
