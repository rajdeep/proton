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
    private(set) var activeProcessors = [TextProcessing]()
    weak var editor: EditorView?

    init(editor: EditorView) {
        self.editor = editor
    }

    var sortedProcessors: [TextProcessing] {
        return activeProcessors.sorted { $0.priority > $1.priority }
    }

    func register(_ processor: TextProcessing) {
        register([processor])
    }

    func unregister(_ processor: TextProcessing) {
        unregister([processor])
    }

    func register(_ processors: [TextProcessing]) {
        activeProcessors.append(contentsOf: processors)
    }

    func unregister(_ processors: [TextProcessing]) {
        activeProcessors.removeAll { p in
            processors.contains { $0.name == p.name }
        }
    }

    func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard let editor = editor else { return }
        var executedProcessors = [TextProcessing]()
        var processed = false
        for processor in sortedProcessors {
            processed = processor.process(editor: editor, range: editedRange, changeInLength: delta)
            if processed { executedProcessors.append(processor) }
            if processor.priority == .exclusive, processed == true {
                notifyInterruption(by: processor, editor: editor, at: editedRange)
                break
            }
        }
        editor.delegate?.editor(editor, didExecuteProcessors: executedProcessors, at: editedRange)
    }

    func textStorage(_ textStorage: NSTextStorage, willProcessDeletedText deletedText: NSAttributedString, insertedText: String) {
        for processor in sortedProcessors {
            processor.willProcess(deletedText: deletedText, insertedText: insertedText)
        }
    }

    private func notifyInterruption(by processor: TextProcessing, editor: EditorView, at range: NSRange) {
        let processors = activeProcessors.filter { $0.name != processor.name }
        processors.forEach { $0.processInterrupted(editor: editor, at: range) }
    }
}
