//
//  EditorViewContextSnapshotTests.swift
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
import UIKit
import XCTest
import SnapshotTesting
import ProtonCore

@testable import Proton


class EditorViewContextSnapshotTests: SnapshotTestCase {
    func testSelectsBeforeDeletingImageBasedAttachment() {
        let context = EditorViewContext.shared
        let viewController = EditorTestViewController(context: context)
        let textView = viewController.editor
        let image = AttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40), type: .inline)
        let attachment = Attachment(image: image)
        attachment.selectBeforeDelete = true

        textView.replaceCharacters(in: .zero, with: "In textView ")
        textView.insertAttachment(in: textView.textEndRange, attachment: attachment)
        textView.selectedRange = NSRange(location: textView.textEndRange.location - 2, length: 1)
        viewController.render()
        _ = context.richTextViewContext.textView(textView.richTextView, shouldChangeTextIn: NSRange(location: textView.selectedRange.location - 1, length: 1), replacementText: "")
        addSelectionRects(at: textView.selectedTextRange!, in: textView, color: .cyan)
        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }

}
