//
//  AutogrowingTextViewSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/1/20.
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
import XCTest
import SnapshotTesting

@testable import Proton

class AutogrowingTextViewSnapshotTests: XCTestCase {

    var recordMode = false
    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testRendersTextViewBasedOnContent() {
        let viewController = SnapshotTestViewController()
        let textView = AutogrowingTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Sample with single line text"
        textView.addBorder()

        let view = viewController.unwrappedView
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])

        viewController.render()

        assertSnapshot(matching: view, as: .image, record: recordMode)
    }

    func testRendersMultilineTextViewBasedOnContent() {
        let viewController = SnapshotTestViewController()
        let textView = AutogrowingTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Sample with multiple lines of text. This text flows into the second line because of width constraint on textview"
        textView.addBorder()

        let view = viewController.unwrappedView
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalToConstant: 280),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
        ])

        viewController.render()

        assertSnapshot(matching: view, as: .image, record: recordMode)
    }
}
