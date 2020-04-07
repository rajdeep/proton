//
//  RendererCommandExecutor.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 15/1/20.
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

/// `RendererCommandExecutor` manages all the `RendererView` in the main `RendererView`. Sub renderers may have been added as `Attachment` in the `RendererView`.
/// All the `RendererView`s in the hierarchy sharing the same `RendererContext` will automatically be handled by the `RendererCommandExecutor`.
/// `RendererCommandExecutor` keeps the track of the `RendererView` that has been selected and executes the given command in the active `RendererView`.
public class RendererCommandExecutor {
    private let context: RichTextRendererContext

    /// Initializes the `RendererCommandExecutor`
    /// - Parameter context: The context for the command executor. `RendererCommandExecutor` is capable of executing commands only on the `RendererView`s
    /// which are created using the same `context`. Default value is `RendererViewContext.shared`
    public init(context: RendererViewContext = RendererViewContext.shared) {
        self.context = context.richTextRendererContext
    }

    /// Executes the given command on the active `RendererView` having the same `Context` as the Command Executor. `RendererCommand` will be executed only
    /// if the `RendererCommand.canExecute()` returns `true` for the selected `RendererView`.
    /// - Parameter command: Command to execute
    public func execute(_ command: RendererCommand) {
        guard let activeRenderer = context.activeTextView,
            let editor = activeRenderer.superview as? EditorView,
            let renderer = editor.superview as? RendererView,
            command.canExecute(on: renderer) else { return }
        command.execute(on: renderer)
    }
}
