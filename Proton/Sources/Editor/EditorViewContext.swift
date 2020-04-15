//
//  EditorViewContext.swift
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

    /// EditorView delegate at context level. This delegate will be notified about events in all the Editors that share this particular context.
    /// This is in addition to the `delegate` available on `EditorView` which works at local level for the `EditorView`. If you are interested in
    /// certain `EditorViewDelegate` events for all the editors sharing the same context e.g. an Editor with nested Editors sharing the same context.
    /// - Note:
    /// If the `EditorView` is instantiated without providing an explicit context, `delegate` can be set on `EditorViewContext.shared` which
    /// is the default context for all the editors.
    public weak var delegate: EditorViewDelegate?

    /// Default shared context. Use this in case there is only a single `EditorView` on the screen at the root level.
    public static let shared = EditorViewContext(name: "shared_editor_context")

    /// `EditorView` for this context that is currently active.
    public var activeEditorView: EditorView? {
        return richTextViewContext.activeTextView?.editorView
    }

    /// Initializes a new context
    /// - Parameter name: Friendly name for the context.
    public init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        richTextViewContext = RichTextEditorContext()
    }
}
