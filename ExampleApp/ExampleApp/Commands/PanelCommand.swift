//
//  PanelCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class PanelCommand: EditorCommand {
    func execute(on editor: EditorView) {
        let selectedText = editor.selectedText

        let attachment = PanelAttachment(frame: .zero)
        attachment.selectBeforeDelete = true
        let panel = attachment.view
        panel.editor.maxHeight = 300
        panel.editor.replaceCharacters(in: .zero, with: selectedText)
        panel.editor.selectedRange = panel.editor.textEndRange

        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    }

    func canExecute(on editor: EditorView) -> Bool {
        let panel = PanelView()
        let minSize = panel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return minSize.width < editor.frame.width
    }
}
