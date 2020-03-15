//
//  RendererCommandExecutor.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

/// Describes a command that can be executed on `RendererView`. A command may be invoked directly on the `renderer` by providing an instance.
/// However, in a typical usage scenario, these should be invoked via `RendererCommandExecutor` which manages all the `RendererView`s in the
/// view including the ones that are contained in the attachments.
public protocol RendererCommand {
    /// Determines if the current command can be executed on the given `RendererView`. When a command is executed using `RendererCommandExecutor`,
    /// it ensures that only the commands returning `true` for the active `RendererView` are executed when invoked. Defaults to `true`.
    /// - Parameter renderer: `EditorView` to execute the command on.
    func canExecute(on renderer: RendererView) -> Bool

    /// Execute the command on the given `EditorView`. You may use `selectedRange` property of `EditorView` if the command operates on
    /// the selected text only. for e.g. a command to make selected text bold.
    /// - Parameter renderer: `EditorView` to execute the command on.
    func execute(on renderer: RendererView)
}

public extension RendererCommand {
    func canExecute(on _: RendererView) -> Bool {
        true
    }
}
