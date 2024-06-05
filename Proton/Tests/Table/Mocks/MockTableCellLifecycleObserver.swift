//
//  MockTableCellLifecycleObserver.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/6/2024.
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

class MockTableCellLifecycleObserver: TableCellLifecycleObserver {
    var onDidAddCellToViewport: ((_ tableView: TableView, _ cell: TableCell) -> Void)?
    var onDidRemoveCellFromViewport: ((_ tableView: TableView, _ cell: TableCell) -> Void)?

    func tableView(_ tableView: TableView, didAddCellToViewport cell: TableCell) {
        onDidAddCellToViewport?(tableView, cell)
    }

    func tableView(_ tableView: TableView, didRemoveCellFromViewport cell: TableCell) {
        onDidRemoveCellFromViewport?(tableView, cell)
    }
}
