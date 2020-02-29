//
//  TextProcessing.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 9/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
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

    func willProcess(deletedText: NSAttributedString, insertedText: String)

    /// Allows to change attributes and text in the `EditorView` as the text is changed.
    /// - Parameter editor:`EditorView` in which text is being changed.
    /// - Parameter editedRange: Current range that is being modified.
    /// - Parameter delta: Change in length of the text as a result of typing text. The length may be more than 1 if multiple characters are selected
    /// before content is typed. It may also happen if text containing a string is pasted.
    /// - Parameter processed: Set this to `true` is the `TextProcessor` has made any changes to the text or attributes in the `EditorView`
    /// - Returns: Return `true` to indicate the processing had been done by the current processor. In case of .exclusive priority processors,
    /// returning `true` notifies all other processors of interruption.
    func process(editor: EditorView, range editedRange: NSRange, changeInLength delta: Int) -> Processed

    /// Fired when processing has been interrupted by another `TextProcessor` running in the same pass. This allows `TextProcessor` to revert
    /// any changes that may not have been committed.
    /// - Parameter editor:`EditorView` in which text is being changed.
    /// - Parameter range: Current range that is being modified.
    func processInterrupted(editor: EditorView, at range: NSRange) // fired when processor is interrupted as a result of an exclusive priority processor
}

public extension TextProcessing {
    func willProcess(deletedText: NSAttributedString, insertedText: String) { }
}
