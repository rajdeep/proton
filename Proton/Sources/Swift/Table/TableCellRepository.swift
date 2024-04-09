//
//  TableCellRepository.swift
//  Proton
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

// TODO: Structure differently - name better
class TableCellRepository {
    private var contentViews: [TableCellContentView] = []

    func enqueue(cell: TableCell) {
        guard let contentView = cell.contentView else { return }
        contentViews.append(contentView)
        cell.removeContentView()
    }

    func dequeue(for cell: TableCell) {
        let contentView = contentViews.first ??
        TableCellContentView(frame: cell.frame, editor: cell.editorInitializer(), initialHeight: cell.initialHeight, containerCell: cell)
        cell.addContentView(contentView)
    }
}
