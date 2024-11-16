//
//  SnapshotTestCase.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 26/6/2022.
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
import XCTest
import SnapshotTesting

class SnapshotTestCase: XCTestCase {
    var recordMode = false

    override func invokeTest() {
        withSnapshotTesting(record: .all, diffTool: .ksdiff) {
            super.invokeTest()
        }
    }
}
