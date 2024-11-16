//
//  EditorCommandSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 8/1/20.
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

class EditorCommandSnapshotTests: SnapshotTestCase {
    func testExecutesCommandOnNestedEditors() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let offsetProvider = MockAttachmentOffsetProvider()
        offsetProvider.offset = CGPoint(x: 0, y: -4)

        editor.font = UIFont.systemFont(ofSize: 12)

        var panel = PanelView()
        panel.backgroundColor = .cyan
        panel.layer.borderWidth = 1.0
        panel.layer.cornerRadius = 4.0
        panel.layer.borderColor = UIColor.black.cgColor

        let attachment = Attachment(panel, size: .fullWidth)
        panel.boundsObserver = attachment
        panel.editor.font = editor.font

        panel.attributedText = NSAttributedString(string: "In full-width attachment")

        editor.replaceCharacters(in: .zero, with: "This text is in Editor ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        let context = EditorViewContext.shared
        let commandExecutor = EditorCommandExecutor(context: context)

        let redColorCommand = MockEditorCommand { editor in
            editor.addAttributes([.foregroundColor: UIColor.red], at: editor.selectedRange)
        }

        let blueColorCommand = MockEditorCommand { editor in
            editor.addAttributes([.foregroundColor: UIColor.blue], at: editor.selectedRange)
        }

        editor.selectedRange = NSRange(location: 5, length: 4)
        context.richTextViewContext.textViewDidBeginEditing(editor.richTextView)
        commandExecutor.execute(redColorCommand)

        context.richTextViewContext.textViewDidEndEditing(editor.richTextView)

        panel.editor.richTextView.selectedRange = NSRange(location: 2, length: 11)
        context.richTextViewContext.textViewDidBeginEditing(panel.editor.richTextView)
        commandExecutor.execute(blueColorCommand)

        viewController.render()

        assertSnapshot(of: viewController.view, as: .image, record: recordMode)
    }
}
