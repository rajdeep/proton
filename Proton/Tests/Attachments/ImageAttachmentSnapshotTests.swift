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

class ImageAttachmentSnapshotTests: SnapshotTestCase {
    func testRendersImageBasedInlineAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor
        let image = InlineAttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40))
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersImageBasedBlockAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor
        let image = BlockAttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40))
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersUpdatedImageInAttachment() {
        let viewController = EditorTestViewController()
        let textView = viewController.editor
        let image = BlockAttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40))
        let attachment = Attachment(image: image)

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.replaceCharacters(in: textView.textEndRange, with: "Text after attachment")

        viewController.render()
        attachment.updateImage(UIImage(systemName: "car.2.fill")!, size: CGSize(width: 100, height: 100))
        viewController.render()
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

}
