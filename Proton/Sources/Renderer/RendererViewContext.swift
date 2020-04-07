//
//  RendererViewContext.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/1/20.
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

/// Describes the context for the `RendererView`. A context is used to execute the commands using `RendererCommandExecutor`. In a typical scenario, where there are
/// multiple levels of `RendererView`s that are contained in another `RendererView` by virtue of being in `Attachment`s, all the `RendererView`s sharing the same
/// context automatically share the `RendererCommandExecutor`. i.e. the `RendererCommandExecutor` operates on only those `RendererView`s which have the same
/// context as provided to the `RendererCommandExecutor`.
public class RendererViewContext {
    let richTextRendererContext: RichTextRendererContext

    /// Identifies the `RendererViewContext`uniquely.
    public let id: String

    /// Friendly name for the context. It is possible to create multiple `RendererViewContext` using the same name.
    /// A context is uniquely identified by `id` and not the name.
    public let name: String

    /// Default shared context. Use this in case there is only a single `RendererView` on the screen at the root level.
    public static let shared = RendererViewContext(name: "shared_renderer_context")

    /// Initializes a new context
    /// - Parameter name: Friendly name for the context.
    public init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        richTextRendererContext = RichTextRendererContext()
    }
}
