//
//  EditorTextInputController.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/12/24.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
@testable import Proton

class EditorTextInputController {
    let editor: EditorView

    init(editor: EditorView) {
        self.editor = editor
    }

    func sendKey(_ key: EditorKey, at range: NSRange? = nil) {
        let rangeToUse = range ?? editor.selectedRange
        switch key {
        case .enter:
            editor.replaceCharacters(in: rangeToUse, with: NSAttributedString(string: "\n"))
        case .backspace:
            editor.replaceCharacters(in: rangeToUse, with: NSAttributedString(string: "\n"))
        case .tab:
            editor.replaceCharacters(in: rangeToUse, with: NSAttributedString(string: "\n"))
        case .other(let uIKey):
            break
        }
    }
}
