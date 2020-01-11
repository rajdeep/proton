//
//  TextProcessor.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

class TextProcessor: NSObject, NSTextStorageDelegate {
    private var activeProcessors = [TextProcessing]()
    weak var editor: EditorView?

    init(editor: EditorView) {
        self.editor = editor
    }

    var sortedProcessors: [TextProcessing] {
        return activeProcessors.sorted { $0.priority > $1.priority }
    }

    func register(_ processor: TextProcessing) {
        activeProcessors.append(processor)
    }

    func unregister(_ command: TextProcessing) {
        activeProcessors.removeAll { $0.name == command.name }
    }

    func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard let editor = editor else { return }

        var processed = false
        for processor in sortedProcessors {
            processor.process(editor: editor, range: editedRange, changeInLength: delta, processed: &processed)
            if processor.priority == .exclusive && processed == true {
                notifyInterruption(by: processor, editor: editor, at: editedRange)
                break
            }
        }
    }

    private func notifyInterruption(by processor: TextProcessing, editor: EditorView, at range: NSRange) {
        let processors = activeProcessors.filter{ $0.name != processor.name }
        processors.forEach { $0.processInterrupted(editor: editor, at: range) }
    }
}
