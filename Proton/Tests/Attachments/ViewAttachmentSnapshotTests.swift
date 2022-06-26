//
//  ViewAttachmentSnapshotTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 5/1/20.
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

class ViewAttachmentSnapshotTests: SnapshotTestCase {
    func testMatchContentRendering() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let attachment = makeDummyAttachment(text: "in attachment", size: .matchContent)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testFallsToNextLineForLongContent() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let attachment = makeDummyAttachment(text: "Long text in attachment", size: .matchContent)

        textView.replaceCharacters(in: .zero, with: "In textView")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: NSAttributedString(string: "after."))

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testMatchContainerRendering() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let attachment = makeDummyAttachment(text: "in attachment", size: .fullWidth)

        textView.replaceCharacters(in: .zero, with: "In textView")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testFixedWidthRendering() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let attachment = makeDummyAttachment(text: "fixed width attachment", size: .fixed(width: 100))

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "and some more text after it.")

        viewController.render(size: CGSize(width: 300, height: 120))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testPercentBasedRendering() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        // TODO: validate incorrect snapshot rendering
//        let attachment = makeDummyAttachment(text: "percent width attachment", size: .percent(width: 75))
        let attachment = makeDummyAttachment(text: "attachment with percent based width", size: .percent(width: 75))

        textView.replaceCharacters(in: .zero, with: "In textView")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)

        viewController.render(size: CGSize(width: 300, height: 120))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testWidthRangeRendering() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let attachment1 = makeDummyAttachment(text: "short", size: .range(minWidth: 60, maxWidth: 200))
        let attachment2 = makeDummyAttachment(text: "some relatively long text", size: .range(minWidth: 60, maxWidth: 200))

        textView.replaceCharacters(in: .zero, with: "Short text ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment1)
        textView.replaceCharacters(in: textView.textEndRange, with: "and some long text ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment2)

        viewController.render(size: CGSize(width: 300, height: 120))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    private func makeDummyAttachment(text: String, size: AttachmentSize) -> Attachment {
        let textView = RichTextAttachmentView(context: RichTextViewContext())
        textView.textContainerInset = .zero
        textView.layoutMargins = .zero
        textView.text = text
        textView.backgroundColor = .yellow
        let attachment = Attachment(textView, size: size)
        attachment.offsetProvider = self
        return attachment
    }
}

extension ViewAttachmentSnapshotTests: AttachmentOffsetProviding {
    func offset(for attachment: Attachment, in textContainer: NSTextContainer, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGPoint {
        return CGPoint(x: 0, y: -3)
    }
}
