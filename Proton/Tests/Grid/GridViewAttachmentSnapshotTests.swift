//
//  GridViewAttachmentTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
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

@testable import Proton

class GridViewAttachmentSnapshotTests: XCTestCase {
    var recordMode = false

    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testRendersGridViewAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fixed(30)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
                GridColumnConfiguration(dimension: .fractional(0.45)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 300))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersGridViewAttachmentWithFractionalWidth() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
                GridColumnConfiguration(dimension: .fractional(0.25)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 80, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 120, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testUpdatesCellSizeBasedOnContent() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        attachment.view.grid.cells[0].editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test long text in the first cell"))

        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testMaintainsRowHeightBasedOnContent() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let config = GridConfiguration(
            columnsConfiguration: [
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
                GridColumnConfiguration(dimension: .fractional(0.33)),
            ],
            rowsConfiguration: [
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
                GridRowConfiguration(minRowHeight: 40, maxRowHeight: 400),
            ])
        let attachment = GridViewAttachment(config: config, initialSize: CGSize(width: 400, height: 350))

        editor.replaceCharacters(in: .zero, with: "Some text in editor")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after grid")

        let cell00Editor = attachment.view.grid.cells[0].editor
        let cell01Editor = attachment.view.grid.cells[1].editor

        // Render text which expands the first row
        cell00Editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test some text cell"))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)


        // Render text which expands the first row with longer text in second cell
        cell01Editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test longer text in the second cell"))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Render text which shrinks the first row due to shorter text in second cell
        cell01Editor.replaceCharacters(in: cell01Editor.attributedText.fullRange, with: NSAttributedString(string: "Short text"))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Resets to blank state
        cell00Editor.replaceCharacters(in: cell00Editor.attributedText.fullRange, with: NSAttributedString(string: ""))
        cell01Editor.replaceCharacters(in: cell01Editor.attributedText.fullRange, with: NSAttributedString(string: ""))
        viewController.render(size: CGSize(width: 400, height: 350))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
}
