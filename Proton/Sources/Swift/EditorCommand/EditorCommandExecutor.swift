//
//  EditorCommandExecutor.swift
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

public protocol EditorCommandExecutorDelegate: AnyObject {
    func willExecuteCommand(_ command: EditorCommand, on editor: EditorView)
    func didExecuteCommand(_ command: EditorCommand, on editor: EditorView)
}

/// `EditorCommandExecutor` manages all the `EditorView` in the main `EditorView`. Sub editors may have been added as `Attachment` in the `EditorView`.
/// All the `EditorView`s in the hierarchy sharing the same `EditorContext` will automatically be handled by the `EditorCommandExecutor`.
/// `EditorCommandExecutor` keeps the track of the `EditorView` that has the focus and executes the given command in the active `EditorView`.
public class EditorCommandExecutor {
    private let context: RichTextEditorContext

    public weak var delegate: EditorCommandExecutorDelegate?

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
        guard let editor = context.activeTextView?.editorView,
              editor.isCommandRegistered(command.name),
              command.canExecute(on: editor)
        else { return }
        delegate?.willExecuteCommand(command, on: editor)
        command.execute(on: editor)
        delegate?.didExecuteCommand(command, on: editor)
    }
}
