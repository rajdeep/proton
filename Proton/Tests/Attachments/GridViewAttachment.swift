//
//  GridViewAttachment.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
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
import UIKit
import Proton

extension EditorContent.Name {
    static let grid = EditorContent.Name("grid")
}

public class GridViewAttachment: Attachment {
    public let view: GridView
    public init(config: GridConfiguration) {
        view = GridView(config: config)
        super.init(view, size: .fullWidth)
        view.boundsObserver = self
    }

    public init(config: GridConfiguration, cells: [GridCell]) {
        view = GridView(config: config, cells: cells)
        super.init(view, size: .fullWidth)
        view.boundsObserver = self
    }
}

extension GridView: AttachmentViewIdentifying {
    public var name: EditorContent.Name {
        return .grid
    }

    public var type: AttachmentType { .block }
}

extension GridView: BackgroundColorObserving {
    public func containerEditor(_ editor: EditorView, backgroundColorUpdated color: UIColor?, oldColor: UIColor?) {
        backgroundColor = color
    }
}
