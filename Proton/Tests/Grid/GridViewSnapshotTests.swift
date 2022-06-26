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

class GridViewSnapshotTests: SnapshotTestCase {
    func testRendersGridView() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 30, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 80, maxRowHeight: 400),
            ])
        let gridView = GridView(config: config, initialSize: CGSize(width: 350, height: 200))

        let vc = GenericViewTestViewController(contentView: gridView)
        vc.render(size: CGSize(width: 350, height: 200))
        assertSnapshot(matching: vc.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAsSelected() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 30, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 80, maxRowHeight: 400),
            ])
        let gridView = GridView(config: config, initialSize: CGSize(width: 350, height: 200))
        gridView.isSelected = true
        let vc = GenericViewTestViewController(contentView: gridView)
        vc.render(size: CGSize(width: 350, height: 200))
        assertSnapshot(matching: vc.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAsSelectedWithRedColor() {
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
                GridColumnConfiguration(dimension: .fixed(100)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 30, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 50, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 80, maxRowHeight: 400),
            ])
        let gridView = GridView(config: config, initialSize: CGSize(width: 350, height: 200))
        gridView.selectionColor = UIColor.red
        gridView.isSelected = true
        let vc = GenericViewTestViewController(contentView: gridView)
        vc.render(size: CGSize(width: 350, height: 200))
        assertSnapshot(matching: vc.view, as: .image, record: recordMode)
    }

//    func testRendersGridViewWithFractionalColumns() {
//        let config = GridConfiguration(
//            columnsConfiguration: [
//                GridColumnConfiguration(dimension: .fractional(0.33)),
//                GridColumnConfiguration(dimension: .fractional(0.33)),
//                GridColumnConfiguration(dimension: .fractional(0.33)),
//            ],
//            rowsConfiguration: [
//                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
//                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
//            ])
//
//        let gridView = GridView(config: config, initialSize: CGSize(width: 400, height: 350))
//
//        let vc = GenericViewTestViewController(contentView: gridView)
//        vc.render(size: CGSize(width: 400, height: 300))
//        assertSnapshot(matching: vc.view, as: .image, record: recordMode)
//    }
}
