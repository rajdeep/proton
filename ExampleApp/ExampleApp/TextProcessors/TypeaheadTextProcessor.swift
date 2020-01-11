//
//  TypeaheadTextProcessor.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

protocol TypeaheadTextProcessorDelegate: class {
    func typeaheadQueryDidChange(trigger: String, query: String, range: NSRange)
    func typeadheadQueryDidEnd()
}

extension NSAttributedString.Key {
    static let Typeahead = NSAttributedString.Key.init("Typeahead")
}

class TypeaheadTextProcessor: TextProcessing {

    var name: String { return "Typeahead" }

    var priority: TextProcessingPriority {
        return .exclusive
    }

    weak var delegate: TypeaheadTextProcessorDelegate?

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int, processed: inout Bool) {
        //        guard let range = typeAheadRange(from: textStorage, editedRange: editedRange) else { return }
        let textStorage = editor.attributedText
        guard let range = textStorage.reverseRange(of: "@", currentPosition: editedRange.location + editedRange.length),
            isValidTrigger(editor: editor, range: range.firstCharacterRange) else { return }

        let triggerRange = NSRange(location: range.location, length: 1)
        let queryRange = NSRange(location: range.location + 1, length: range.length - 1)
        let query = textStorage.attributedSubstring(from: queryRange).string
        let trigger = textStorage.attributedSubstring(from: triggerRange)

        let isCancelled = trigger.attributes(at: 0, effectiveRange: nil).contains { attr in
            attr.key == .Typeahead && attr.value as? Bool == false
        }

        guard isCancelled == false else { return }

        if query.components(separatedBy: " ").count >= 3 {
            editor.addAttributes([.Typeahead: false], at: triggerRange)
            editor.removeAttribute(NSAttributedString.Key.foregroundColor, at: range)
            delegate?.typeadheadQueryDidEnd()
        } else {
            delegate?.typeaheadQueryDidChange(trigger: trigger.string, query: query, range: range)
            editor.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.blue], at: range)
        }

        processed = true
    }

    func processInterrupted(editor: EditorView, at range: NSRange) { }

    private func isValidTrigger(editor: EditorView, range: NSRange) -> Bool {
        guard range != NSRange(location: 0, length: 1) else { return true }

        let previousCharRange = NSRange(location: range.location - 1, length: 1)
        let previousChar = editor.attributedText.attributedSubstring(from: previousCharRange).string

        return previousChar == " "
    }
}

extension NSAttributedString {
    func reverseRange(of delimiter: String, currentPosition: Int) -> NSRange? {
        guard currentPosition <=  string.utf16.count else {
            return nil
        }
        let triggerCharacterSet = CharacterSet(charactersIn: delimiter)
        let string = self.string as NSString
        let cursorRange = NSRange(location: 0, length: currentPosition)
        let text = string.substring(with: cursorRange) as NSString
        let triggerRange = text.rangeOfCharacter(from: triggerCharacterSet, options: [.backwards])
        guard triggerRange.location != NSNotFound else {
            return nil
        }

        let typeaheadLength = currentPosition - triggerRange.location
        let typeAheadRange = NSRange(location: triggerRange.location, length: typeaheadLength)
        return typeAheadRange
    }
}
