//
//  MockEditorCommand.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 23/2/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class MockEditorCommand: EditorCommand {
    var onCanExecute: (EditorView) -> Bool
    var onExecute: (EditorView) -> Void

    init(onCanExecute: @escaping ((EditorView) -> Bool) = { _ in true },
         onExecute: @escaping ((EditorView) -> Void)) {
        self.onCanExecute = onCanExecute
        self.onExecute = onExecute
    }

    func canExecute(on editor: EditorView) -> Bool {
        return onCanExecute(editor)
    }

    func execute(on editor: EditorView) {
        onExecute(editor)
    }
}
