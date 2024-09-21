//
//  TypeaheadTextProcessor.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 9/1/20.
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

protocol TypeaheadTextProcessorDelegate: AnyObject {
    func typeaheadQueryDidChange(trigger: String, query: String, range: NSRange)
    func typeadheadQueryDidEnd(reason: TypeaheadExitReason)
}

extension NSAttributedString.Key {
    static let typeahead = NSAttributedString.Key("Typeahead")
}

enum TypeaheadExitReason {
    case triggerDeleted
    case completed
}

class TypeaheadTextProcessor: TextProcessing {

    var name: String { return "Typeahead" }

    var priority: TextProcessingPriority {
        return .exclusive
    }

    var isRunOnSettingText: Bool {
        true
    }

    weak var delegate: TypeaheadTextProcessorDelegate?
    var triggerDeleted = false

    func willProcess(editor: EditorView, deletedText: NSAttributedString, insertedText: NSAttributedString, range: NSRange) {
        let deleted = NSMutableAttributedString(attributedString: deletedText)
        let range = deleted.mutableString.range(of: "@")
        if range.location != NSNotFound {
            let triggerChar = deletedText.attributedSubstring(from: range)
            let typeaheadAttribute = triggerChar.attribute(.typeahead, at: 0, effectiveRange: nil) as? Bool ?? true
            if typeaheadAttribute != false {
                triggerDeleted = true
                delegate?.typeadheadQueryDidEnd(reason: .triggerDeleted)
            }
        }
    }

    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed {
        guard triggerDeleted == false else {
            editor.removeAttribute(.foregroundColor, at: editedRange)
            triggerDeleted = false
            return false
        }

        let textStorage = editor.attributedText
        guard let range = textStorage.reverseRange(of: "@", currentPosition: editedRange.location + editedRange.length),
            isValidTrigger(editor: editor, range: range.firstCharacterRange) else { return false }

        let triggerRange = NSRange(location: range.location, length: 1)
        let queryRange = NSRange(location: range.location + 1, length: range.length - 1)
        let query = textStorage.attributedSubstring(from: queryRange).string
        let trigger = textStorage.attributedSubstring(from: triggerRange)

        let isCancelled = trigger.attributes(at: 0, effectiveRange: nil).contains { attr in
            attr.key == .typeahead && attr.value as? Bool == false
        }

        guard isCancelled == false else { return false }

        if query.components(separatedBy: " ").count >= 3 {
            editor.addAttributes([.typeahead: false], at: triggerRange)
            editor.removeAttribute(.foregroundColor, at: range)
            delegate?.typeadheadQueryDidEnd(reason: .completed)
        } else {
            delegate?.typeaheadQueryDidChange(trigger: trigger.string, query: query, range: range)
            editor.addAttributes([.foregroundColor: UIColor.systemBlue], at: range)
        }

        return true
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
        guard currentPosition <= string.utf16.count else {
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
