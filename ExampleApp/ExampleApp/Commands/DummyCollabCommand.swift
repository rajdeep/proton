//
//  DummyCollabCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 10/2/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class DummyCollabCommand: EditorCommand {
    func execute(on editor: EditorView) {
        let caretRect = editor.caretRect(for: 0)

        let caretView = UIView(frame: caretRect)
        caretView.backgroundColor = .systemRed
        caretView.blink()
        editor.addSubview(caretView)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {[editor] in
            let text = "collab edit "
            editor.replaceCharacters(in: .zero, with: text)
            editor.selectedRange = NSRange(location: editor.selectedRange.location + text.count, length: 0)
            let insertedTextRange = NSRange(location: 0 , length: text.count)
            let selectionRangeRect = editor.rects(for: insertedTextRange)
            let selectionView = UIView(frame: selectionRangeRect[0])
            selectionView.backgroundColor = .systemRed
            selectionView.layer.cornerRadius = 4.0
            editor.addSubview(selectionView)
            selectionView.flash { view in
                view.removeFromSuperview()
            }
            let updatedFrame = editor.caretRect(for: text.count)
            caretView.frame = updatedFrame
        }
    }
}
