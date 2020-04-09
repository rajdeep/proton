//
//  TextProcessing.swift
//  Proton
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

public typealias TextProcessingPriority = Int
public extension TextProcessingPriority {
    static let exclusive: TextProcessingPriority = 1000
    static let high: TextProcessingPriority = 750
    static let medium: TextProcessingPriority = 500
    static let low: TextProcessingPriority = 250
}

public typealias Processed = Bool

/// An object capable of intercepting and modifying the text and attributes in an `EditorView` when registered with the `EditorView`.
public protocol TextProcessing {

    /// Name of the TextProcessor
    var name: String { get }

    /// Priority of the TextProcessor. An `EditorView` can have multiple `TextProcessors` registered. These will be executed in the order of `Priority`.
    /// - Attention: When a `textProcessor` with priority is set to `.exclusive` is executed, it will prevent all other registered `TextProcessors` from being
    /// executed. If multiple such `TextProcessors` are registered, only the one registered earlier is executed. When this happens, all other registered
    /// `TextProcessors` which are prevented from being executed receive `processInterrupted` with the `range` in which exclusive `TextProcessor` is
    /// executed. It is responsibility of these `TextProcessors` to do any cleanup/rollback if that needs to be done.
    var priority: TextProcessingPriority { get }

    /// Invoked before changes are processed by the editor.
    /// - Attention:
    /// This is fired before the text has changed in the editor. This can be helpful if any state needs to be changed based on edited text.
    /// However, it should be noted that the changes are done only in `process` and not in this function owing to the lifecycle of TextKit components.
    /// - Parameters:
    ///   - deletedText: Text that has been deleted, if any.
    ///   - insertedText: Text that is inserted, if any.
    func willProcess(deletedText: NSAttributedString, insertedText: NSAttributedString)

    /// Allows to change attributes and text in the `EditorView` as the text is changed.
    /// - Parameters:
    ///   - editor:`EditorView` in which text is being changed.
    ///   - editedRange: Current range that is being modified.
    ///   - delta: Change in length of the text as a result of typing text. The length may be more than 1 if multiple characters are selected
    /// before content is typed. It may also happen if text containing a string is pasted.
    ///   - processed: Set this to `true` is the `TextProcessor` has made any changes to the text or attributes in the `EditorView`
    /// - Returns: Return `true` to indicate the processing had been done by the current processor. In case of .exclusive priority processors,
    /// returning `true` notifies all other processors of interruption.
    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed

    /// Allows to change attributes and text in the `EditorView` as the text is changed.
    /// - Parameters:
    ///   - editor:`EditorView` in which text is being changed.
    ///   - key: `EditorKey` that is entered.
    ///   - modifierFlags: The bit mask of modifier flags that were pressed with the key.
    ///   - editedRange: Current range that is being modified.
    func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange)

    /// Fired when processing has been interrupted by another `TextProcessor` running in the same pass. This allows `TextProcessor` to revert
    /// any changes that may not have been committed.
    /// - Parameter editor:`EditorView` in which text is being changed.
    /// - Parameter range: Current range that is being modified.
    func processInterrupted(editor: EditorView, at range: NSRange) // fired when processor is interrupted as a result of an exclusive priority processor

    /// Notifies the processor that the selected range has changed in the EditorView due to a reason other than typing text
    /// for e.g. moving cursor using keyboard, mouse or tap.
    /// - Note:
    /// This function is also called if the user selects text by dragging. Each individual character selection during drag operation
    /// results in an independent call to this function. If old or new range has zero length, it indicates the caret (insertion point).
    /// If the range object is nil, it indicates that there is no previous/current selection.
    /// - Parameters:
    ///   - editor: EditorView in which selected range changed
    ///   - oldRange: Original range before the change
    ///   - newRange: Current range after the change
    func selectedRangeChanged(editor: EditorView, oldRange: NSRange?, newRange: NSRange?)
}

public extension TextProcessing {
    func willProcess(deletedText: NSAttributedString, insertedText: NSAttributedString) { }
    func handleKeyWithModifiers(editor: EditorView, key: EditorKey, modifierFlags: UIKeyModifierFlags, range editedRange: NSRange) { }
    func selectedRangeChanged(editor: EditorView, oldRange: NSRange?, newRange: NSRange?) { }
}
