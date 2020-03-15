//
//  AutogrowingTextViewSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import FBSnapshotTestCase
import Foundation
import XCTest

@testable import Proton

class AutogrowingTextViewSnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testRendersTextViewBasedOnContent() {
        let viewController = SnapshotTestViewController()
        let textView = AutogrowingTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Sample with single line text"
        textView.addBorder()

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        ])

        viewController.render()

        FBSnapshotVerifyView(view)
    }

    func testRendersMultilineTextViewBasedOnContent() {
        let viewController = SnapshotTestViewController()
        let textView = AutogrowingTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Sample with multiple lines of text. This text flows into the second line because of width constraint on textview"
        textView.addBorder()

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalToConstant: 280),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
        ])

        viewController.render()

        FBSnapshotVerifyView(view)
    }
}
