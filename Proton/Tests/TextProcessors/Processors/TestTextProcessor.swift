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
    var name: String { "TestTextProcessor" }

    var priority: TextProcessingPriority = .medium

    var onProcess: ((EditorView, NSRange) -> Processed)?
    var onProcessInterrupted: ((EditorView, NSRange) -> Void)?

    func process(editor: EditorView, range editedRange: NSRange, changeInLength _: Int) -> Processed {
        onProcess?(editor, editedRange) ?? false
    }

    func processInterrupted(editor: EditorView, at range: NSRange) {
        onProcessInterrupted?(editor, range)
    }
}
