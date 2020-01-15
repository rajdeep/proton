//
//  EditorCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

/// Describes a command that can be executed on `EditorView`. A command may be invoked directly on the `editor` by providing an instance.
/// However, in a typical usage scenario, these should be invoked via `EditorCommandExecutor` which manages all the `EditorView`s in the
/// view including the ones that are contained in the attachments.
public protocol EditorCommand {

    /// Determines if the cutrrent command can be executed on the given `EditorView`. When a command is executed using `EditorCommandExecutor`, it ensures
    /// that only the commands returning `true` for the active `EditorView` are executed when invoked. Defaults to `true`.
    /// - Parameter editor: `EditorView` to execute the command on.
    func canExecute(on editor: EditorView) -> Bool

    /// Execute the command on the given `EditorView`. You may use `selectedRange` property of `EditorView` if the command operates on
    /// the selected text only. for e.g. a command to make selected text bold.
    /// - Parameter editor: `EditorView` to execute the command on.
    func execute(on editor: EditorView)
}

public extension EditorCommand {
    func canExecute(on editor: EditorView) -> Bool {
        return true
    }
}
