//
//  MockTextProcessor.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
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

class MockTextProcessor: TextProcessing {
    let name: String
    var priority: TextProcessingPriority = .medium
    var isRunOnSettingText: Bool = true

    var onWillProcess: ((EditorView, NSAttributedString, NSAttributedString, NSRange) -> Void)?
    var onProcess: ((EditorView, NSRange, Int) -> Void)?
    var onKeyWithModifier: ((EditorView, EditorKey, UIKeyModifierFlags, NSRange) -> Void)?
    var onProcessInterrupted: ((EditorView, NSRange) -> Void)?
    var onSelectedRangeChanged: ((EditorView, NSRange?, NSRange?) -> Void)?
    var onDidProcess: ((EditorView) -> Void)?
    var onShouldProcess: ((EditorView, NSRange, String) -> Bool)?

    var willProcessEditing: ((EditorView, NSTextStorage.EditActions, NSRange, Int) -> Void)?
    var didProcessEditing: ((EditorView, NSTextStorage.EditActions, NSRange, Int) -> Void)?

    var processorCondition: (EditorView, NSRange) -> Bool

    init(name: String = "MockTextProcessor", processorCondition: @escaping (EditorView, NSRange) -> Bool = { _, _ in true }) {
        self.name = name
        self.processorCondition = processorCondition
    }

    func willProcess(editor: EditorView, deletedText: NSAttributedString, insertedText: NSAttributedString, range: NSRange) {
        onWillProcess?(editor, deletedText, insertedText, range)
    }

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed {
        guard processorCondition(editor, editedRange) else {
            return false
        }
        onProcess?(editor, editedRange, delta)
        return true
    }

    func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange) {
        guard processorCondition(editor, editedRange) else { return }

        onKeyWithModifier?(editor, key, modifierFlags, editedRange)
    }

    func processInterrupted(editor: EditorView, at range: NSRange) {
        onProcessInterrupted?(editor, range)
    }

    func selectedRangeChanged(editor: EditorView, oldRange: NSRange?, newRange: NSRange?) {
        onSelectedRangeChanged?(editor, oldRange, newRange)
    }

    func didProcess(editor: EditorView) {
        onDidProcess?(editor)
    }

    func shouldProcess(_ editorView: EditorView, shouldProcessTextIn range: NSRange, replacementText text: String) -> Bool {
        return onShouldProcess?(editorView, range, text) ?? true
    }

    func willProcessEditing(editor: EditorView, editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        willProcessEditing?(editor, editedMask, editedRange, delta)
    }

    func didProcessEditing(editor: EditorView, editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        didProcessEditing?(editor, editedMask, editedRange, delta)
    }
}
