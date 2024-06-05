//
//  TableViewAttachment.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 9/4/2024.
//  Copyright © 2024 Rajdeep Kwatra. All rights reserved.
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
    static let table = EditorContent.Name("table")
}

public class TableViewAttachment: Attachment {
    public let view: TableView

    public init(config: GridConfiguration) {
        view = TableView(config: config, tableCellLifeCycleObserver: nil)
        super.init(view, size: .fullWidth)
        view.boundsObserver = self
    }

    public init(config: GridConfiguration, cells: [TableCell]) {
        view = TableView(config: config, cells: cells, tableCellLifeCycleObserver: nil)
        super.init(view, size: .fullWidth)
        view.boundsObserver = self
    }
}

extension TableView: AttachmentViewIdentifying {
    public var name: EditorContent.Name {
        return .table
    }

    public var type: AttachmentType { .block }
}
