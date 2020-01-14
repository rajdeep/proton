//
//  RichTextViewSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 4/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest
import FBSnapshotTestCase

@testable import Proton


class RichTextViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()

        recordMode = false
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

        FBSnapshotVerifyView(view)
    }

    func testRendersMultilineTextViewBasedOnContent() {
        let viewController = SnapshotTestViewController()
        let textView = RichTextView(frame: .zero, context: RichTextViewContext())

        let font = assertUnwrap(UIFont(name: "Papyrus", size: 12))
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

        FBSnapshotVerifyView(view)
    }
}
