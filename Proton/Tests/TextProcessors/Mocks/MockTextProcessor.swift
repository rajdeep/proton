//
//  MockTextProcessor.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton

class MockTextProcessor: TextProcessing {
    let name: String
    var priority: TextProcessingPriority = .medium

    var onWillProcess: ((NSAttributedString, String) -> Void)?
    var onProcess: ((EditorView, NSRange, Int) -> Void)?
    var onProcessInterrupted: ((EditorView, NSRange) -> Void)?

    var processorCondition: (EditorView, NSRange) -> Bool

    init(name: String = "MockTextProcessor", processorCondition: @escaping (EditorView, NSRange) -> Bool) {
        self.name = name
        self.processorCondition = processorCondition
    }

    func willProcess(deletedText: NSAttributedString, insertedText: String) {
        onWillProcess?(deletedText, insertedText)
    }

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int, processed: inout Bool) {
        guard processorCondition(editor, editedRange) else {
            processed = false
            return
        }
        onProcess?(editor, editedRange, delta)
        processed = true
    }

    func processInterrupted(editor: EditorView, at range: NSRange) {
        onProcessInterrupted?(editor, range)
    }    
}
