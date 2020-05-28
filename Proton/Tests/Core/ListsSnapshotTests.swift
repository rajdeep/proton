//
//  ListsSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 28/5/20.
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
import FBSnapshotTestCase

@testable import Proton

class ListsSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testSingleLevelList() {
        let text = """
        This is line 1. This is line 1. This is line 1. This is line 1.
        This is line 2.
        This is line 3. This is line 3. This is line 3. This is line 3.
        """

        let paraStyle = NSMutableParagraphStyle.forListLevel(1)

        let attributedText = NSAttributedString(string: text, attributes: [.listItem: 1, .paragraphStyle: paraStyle])
        let view = renderList(text: attributedText, viewSize: CGSize(width: 300, height: 150))

        FBSnapshotVerifyView(view)
    }

    func testMultiLevelList() {
        let sequenceGenerators: [SequenceGenerator] = [NumericSequenceGenerator(), SquareBulletSequenceGenerator()]

        let paraStyle1 = NSMutableParagraphStyle.forListLevel(1)
        let paraStyle2 = NSMutableParagraphStyle.forListLevel(2)

        let text1 = "This is line 1. This is line 1. This is line 1. This is line 1.\n"
        let text11 = "Subitem 1 Subitem 1.\nSubItem 2 SubItem 2.\n"
        let text2 = "This is line 2. This is line 2. This is line 2."

        let attributedString = NSMutableAttributedString(string: text1, attributes: [.paragraphStyle: paraStyle1])
        attributedString.append(NSAttributedString(string: text11, attributes: [.paragraphStyle: paraStyle2]))
        attributedString.append(NSAttributedString(string: text2, attributes: [.paragraphStyle: paraStyle1]))
        attributedString.addAttribute(.listItem, value: 1, range: attributedString.fullRange)

        let view = renderList(text: attributedString, viewSize: CGSize(width: 300, height: 175), sequenceGenerators: sequenceGenerators)
        FBSnapshotVerifyView(view)
    }

    func testSequenceGeneratorsRepetition() {
        let sequenceGenerators: [SequenceGenerator] =
            [NumericSequenceGenerator(), SquareBulletSequenceGenerator(), DiamondBulletSequenceGenerator()]

        let levels = sequenceGenerators.count * 2
        let paraStyles = (1...levels).map { NSMutableParagraphStyle.forListLevel($0) }

        let text = "Text\n"
        let attributedString = NSMutableAttributedString()
        for i in 0..<levels {
            let style = paraStyles[i % levels]
            attributedString.append(NSAttributedString(string: text, attributes: [.paragraphStyle: style]))
            attributedString.append(NSAttributedString(string: text, attributes: [.paragraphStyle: style]))
        }

        attributedString.addAttribute(.listItem, value: 1, range: attributedString.fullRange)

        let attributedText = attributedString
        let view = renderList(text: attributedText, viewSize: CGSize(width: 225, height: 325), sequenceGenerators: sequenceGenerators)

        FBSnapshotVerifyView(view)
    }

    func testMultiLevelRepeatingText() {
        let sequenceGenerators: [SequenceGenerator] =
            [NumericSequenceGenerator(), SquareBulletSequenceGenerator(), NumericSequenceGenerator()]

        let levels = sequenceGenerators.count
        let paraStyles = (1...levels).map { NSMutableParagraphStyle.forListLevel($0) }

        let text = "Text\n"
        let attributedString = NSMutableAttributedString()
        for i in 0..<levels * 2 {
            let style = paraStyles[i % levels]
            attributedString.append(NSAttributedString(string: text, attributes: [.paragraphStyle: style]))
            attributedString.append(NSAttributedString(string: text, attributes: [.paragraphStyle: style]))
        }

        attributedString.addAttribute(.listItem, value: 1, range: attributedString.fullRange)

        let attributedText = attributedString
        let view = renderList(text: attributedText, viewSize: CGSize(width: 225, height: 325), sequenceGenerators: sequenceGenerators)

        FBSnapshotVerifyView(view)
    }

    func renderList(text: NSAttributedString, viewSize: CGSize, sequenceGenerators: [SequenceGenerator] = []) -> UIView {
        let viewController = SnapshotTestViewController()
        let textView = RichTextView(frame: .zero, context: RichTextViewContext())

        textView.sequenceGenerators = sequenceGenerators

        textView.translatesAutoresizingMaskIntoConstraints = false

        textView.attributedText = text
        textView.addBorder()

        let view = viewController.view!
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            textView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        viewController.render(size: viewSize)

        return view
    }
}

extension NSMutableParagraphStyle {
    static var listIndent: CGFloat {
        return 25
    }

    static func forListLevel(_ level: Int) -> NSMutableParagraphStyle {
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.firstLineHeadIndent = CGFloat(level) * listIndent
        paraStyle.headIndent = paraStyle.firstLineHeadIndent
        return paraStyle
    }
}
