//
//  TestTextProcessor.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class TestTextProcessor: TextProcessing {
    var name: String { return "TestTextProcessor" }

    var priority: TextProcessingPriority = .medium

    var onProcess: ((EditorView, NSRange) -> Void)?
    var onProcessInterrupted: ((EditorView, NSRange) -> Void)?

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int, processed: inout Bool) {
        onProcess?(editor, editedRange)
    }

    func processInterrupted(editor: EditorView, at range: NSRange) {
        onProcessInterrupted?(editor, range)
    }
}
