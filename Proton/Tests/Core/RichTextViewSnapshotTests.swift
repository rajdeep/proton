//
//  RichTextViewSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 4/1/20.
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
import ProtonCore

@testable import Proton

class RichTextViewSnapshotTests: XCTestCase {

    var recordMode = false
    override func setUp() {
        super.setUp()

//        recordMode = true
    }

    func testRendersTextInTextView() {
        let viewController = SnapshotTestViewController()
        let textView = RichTextView(frame: .zero, context: RichTextViewContext())
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Sample with single line text"
        textView.addBorder()

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])

        viewController.render()

        assertSnapshot(matching: view, as: .image, record: recordMode)
    }

    func testRendersPlaceholderInTextView() {
        let viewController = SnapshotTestViewController()
        let textView = RichTextView(frame: .zero, context: RichTextViewContext())
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.placeholderText = NSAttributedString(string: "Placeholder text", attributes: [.foregroundColor: UIColor.gray])
        textView.addBorder()

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        textView.attributedText = NSAttributedString(string: "A")
        viewController.render()
        assertSnapshot(matching: view, as: .image, record: recordMode)

        textView.deleteBackward()
        viewController.render()
        assertSnapshot(matching: view, as: .image, record: recordMode)

        textView.attributedText = NSAttributedString(string: "B")
        viewController.render()
        assertSnapshot(matching: view, as: .image, record: recordMode)

        textView.attributedText = NSAttributedString();
        viewController.render()
        assertSnapshot(matching: view, as: .image, record: recordMode)
    }

    func testRendersMultilineTextViewBasedOnContent() {
        let viewController = SnapshotTestViewController()
        let textView = RichTextView(frame: .zero, context: RichTextViewContext())

        guard let font = try? XCTUnwrap(UIFont(name: "Papyrus", size: 12)) else {
            XCTFail("Unable to get font information")
            return
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 10
        paragraphStyle.lineSpacing = 6

        let formattingProvider = MockDefaultTextFormattingProvider(font: font, paragraphStyle: paragraphStyle)
        textView.defaultTextFormattingProvider = formattingProvider

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Sample with multiple lines of text. This text flows into the second line because of width constraint on textview"
        textView.addBorder()

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalToConstant: 280),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
        ])

        viewController.render(size: CGSize(width: 300, height: 150))

        assertSnapshot(matching: view, as: .image, record: recordMode)
    }
}
