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
        var panel = PanelView()
        let selectedText = editor.selectedText
        panel.backgroundColor = .lightGray
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor
        panel.editor.maxHeight = 300
        panel.editor.replaceCharacters(in: .zero, with: selectedText)
        panel.editor.selectedRange = panel.editor.textEndRange

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    }
}
