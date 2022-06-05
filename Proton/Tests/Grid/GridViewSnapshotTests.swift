//
//  GridViewSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/6/2022.
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
import XCTest
import SnapshotTesting

@testable import Proton

class GridViewSnapshotTests: XCTestCase {
    var recordMode = false

    override func setUp() {
        super.setUp()

        recordMode = true
    }

    func testRendersGridView() {
        let config = GridConfiguration(numberOfRows: 2, numberOfColumns: 3, minColumnWidth: 100, maxColumnWidth: 200, minRowHeight: 40, maxRowHeight: 300)
        let gridView = GridView(config: config)

        let vc = GenericViewTestViewController(contentView: gridView)
        vc.render(size: CGSize(width: 350, height: 120))
        assertSnapshot(matching: vc.view, as: .image, record: recordMode)
    }

}
