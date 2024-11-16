//
//  ImageAttachmentSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 20/5/2022.
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
import ProtonCore

@testable import Proton

class AttachmentUpdateSnapshotTests: SnapshotTestCase {
    func testRendersImageBasedInlineAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor
        let image = AttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40), type: .inline)
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }

    func testRendersImageBasedBlockAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor
        let image = AttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40), type: .block)
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }

    func testRendersUpdatedImageInAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor
        let image = AttachmentImage(name: EditorContent.Name("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40), type: .block)
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
        attachment.update(with: AttachmentImage(name: EditorContent.Name("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 80), type: .block))
        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }

    func testRendersUpdatedViewInAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let panel = PanelView()
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let inlineEditor = InlineEditorView()
        inlineEditor.textContainerInset = .zero
        inlineEditor.backgroundColor = .cyan
        inlineEditor.addBorder()

        let attachment = Attachment(inlineEditor, size: .range(minWidth: 50, maxWidth: 100))

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(of: viewController, as: .image, record: recordMode)
        attachment.update(panel, size: .fullWidth)
        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(of: viewController, as: .image, record: recordMode)
    }

    func testRendersUpdatedViewInImageAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let panel = PanelView()
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor


        let image = AttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40), type: .block)
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)

        attachment.update(panel, size: .fullWidth)
        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }


    func testRenderUpdatedImageInViewAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor

        let inlineEditor = InlineEditorView()
        inlineEditor.textContainerInset = .zero
        inlineEditor.backgroundColor = .cyan
        inlineEditor.addBorder()

        let attachment = Attachment(inlineEditor, size: .range(minWidth: 50, maxWidth: 100))

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)

        attachment.update(with: AttachmentImage(name: EditorContent.Name("image"), image: UIImage(systemName: "car.2.fill")!, size: CGSize(width: 80, height: 40), type: .block))
        viewController.render(size: CGSize(width: 300, height: 125))
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }
}
