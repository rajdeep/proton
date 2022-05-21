//
//  ExpandCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 21/5/2022.
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

class ExpandCommand: EditorCommand {
    let name = CommandName("expandCommand")
    func execute(on editor: EditorView) {
        let selectedText = editor.selectedText

        let attachment = ExpandableAttachment(frame: .zero)
        attachment.selectBeforeDelete = true
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)

        let expand = attachment.view
        expand.editor.maxHeight = .max(300)
        expand.editor.registerProcessors(editor.registeredProcessors)
        expand.editor.listFormattingProvider = editor.listFormattingProvider
        expand.editor.replaceCharacters(in: .zero, with: selectedText)
        expand.editor.selectedRange = expand.editor.textEndRange
    }

    func canExecute(on editor: EditorView) -> Bool {
        let expand = ExpandableView()
        let minSize = expand.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return minSize.width < editor.frame.width
    }
}
