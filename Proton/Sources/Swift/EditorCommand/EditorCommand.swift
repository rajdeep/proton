//
//  EditorCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
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

/// Describes a command that can be executed on `EditorView`. A command may be invoked directly on the `editor` by providing an instance.
/// However, in a typical usage scenario, these should be invoked via `EditorCommandExecutor` which manages all the `EditorView`s in the
/// view including the ones that are contained in the attachments.
public protocol EditorCommand: AnyObject {
    /// Identifies a command. This value is used to maintain unique registrations of commands in an Editor. Adding a command with the same name
    /// as one registered already would end up replacing the previously registered command with the same name.
    var name: CommandName { get }

    /// Determines if the current command can be executed on the given `EditorView`. When a command is executed using `EditorCommandExecutor`, it ensures
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
        return editor.registeredCommands?.contains { $0.name == self.name } ?? true
    }
}
