//
//  RendererViewContext.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

/// Describes the context for the `RendererView`. A context is used to execute the commands using `RendererCommandExecutor`. In a typical scenario, where there are
/// multiple levels of `RendererView`s that are contained in another `RendererView` by virtue of being in `Attachment`s, all the `RendererView`s sharing the same
/// context automatically share the `RendererCommandExecutor`. i.e. the `RendererCommandExecutor` operates on only those `RendererView`s which have the same
/// context as provided to the `RendererCommandExecutor`.
public class RendererViewContext {
    let richTextRendererContext: RichTextRendererContext

    /// Identifies the `RendererViewContext`uniquely.
    public let id: String

    /// Friendly name for the context. It is possible to create multiple `RendeererViewContext` using the same name.
    /// A context is uniquely identified by `id` and not the name.
    public let name: String

    /// Default shared context. Use this in case there is onlt a single `RendererView` on the screen at the root level.
    public static let shared = RendererViewContext(name: "shared_renderer_context")

    /// Initializes a new context
    /// - Parameter name: Friendly name for the context.
    public init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        richTextRendererContext = RichTextRendererContext()
    }
}
