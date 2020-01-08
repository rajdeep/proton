//
//  EditorCommandExecutor.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

/// `EditorCommandExecutor` manages all the `EditorView` in the main `EditorView`. Sub editors may have been added as `Attachment` in the `EditorView`.
/// All the `EditorView`s in the hierarchy sharing the same `EditorContext` will automaticlly be handled by the `EditorCommandExecutor`.
/// `EditorCommandExecutor` keeps the track of the `EditorView` that has the focus and executes the given command in the active `EditorView`.
public class EditorCommandExecutor {
    private let context: RichTextViewContext

    /// Initializes the `EditorCommandExecutor`
    /// - Parameter context: The context for the command executor. `EditorCommandExecutor` is capable of executing commands only on the `EditorView`s
    /// which are created using the same `context`. Default value is `EditorViewContext.shared`
    public init(context: EditorViewContext = EditorViewContext.shared) {
        self.context = context.richTextViewContext
    }

    /// Executes the given command on the active `EditorView` having the same `Context` as the Command Executor. `EditorCommand` will be executed only
    /// if the `EditorCommand.canExecute()` returns `true` for the active `EditorView`.
    /// - Parameter command: Command to execute
    public func execute(_ command: EditorCommand) {
        guard let activeEditor = context.activeTextView,
            let editor = activeEditor.superview as? EditorView,
            command.canExecute(on: editor) else { return }
        command.execute(on: editor)
    }
}
