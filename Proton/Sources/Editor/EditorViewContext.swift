//
//  EditorViewContext.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

/// Describes the context for the `EditorView`. A context is used to execute the commands using `EditorCommandExecutor`. In a typical scenario, where there are
/// multiple levels of `EditorView`s that are contained in another `EditorView` by virtue of being in `Attachment`s, all the `EditorView`s sharing the same
/// context automatically share the `EditorCommandExecutor`. i.e. the `EditorCommandExecutor` operates on only those `EditorView`s which have the same
/// context as provided to the `EditorCommandExecutor`.
public class EditorViewContext {
    let richTextViewContext: RichTextEditorContext

    /// Identifies the `EditorViewContext`uniquely.
    public let id: String

    /// Friendly name for the context. It is possible to create multiple `EditorViewContext` using the same name.
    /// A context is uniquely identified by `id` and not the name.
    public let name: String

    /// Default shared context. Use this in case there is only a single `EditorView` on the screen at the root level.
    public static let shared = EditorViewContext(name: "shared_editor_context")

    /// Initializes a new context
    /// - Parameter name: Friendly name for the context.
    public init(name: String) {
        id = UUID().uuidString
        self.name = name
        richTextViewContext = RichTextEditorContext()
    }
}
