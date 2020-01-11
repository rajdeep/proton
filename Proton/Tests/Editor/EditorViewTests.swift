//
//  EditorViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import XCTest

@testable import Proton

class EditorViewTests: XCTestCase {
    func testInvokesRegisteredProcessor() {
        let testExpectation = functionExpectation()
        let editor = EditorView()
        let testString = "test"

        let mockProcessor = MockTextProcessor { editor, editedRange in
            let text = editor.attributedText.attributedSubstring(from: editedRange).string
            XCTAssertEqual(text, testString)
            testExpectation.fulfill()
            return true
        }

        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }

    func testGetsContents() {
        let editor = EditorView()
        let textField = AutogrowingTextField()
        let editorString = NSAttributedString(string: "Some text in Editor ")
        let attachmentString = NSAttributedString(string: "In full-width attachment")
        let textFieldAttachment = Attachment(textField, size: .matchContent)
        textField.attributedText = attachmentString

        let panelView = PanelView()
        let panelAttachment = Attachment(panelView, size: .fullWidth)

        editor.replaceCharacters(in: .zero, with: editorString)
        editor.insertAttachment(in: editor.textEndRange, attachment: textFieldAttachment)
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment)

        let contents = editor.contents()

        XCTAssertEqual(contents.count, 5)
        let paragraphContent = contents[0]
        if case let .text(name, attributedString) = paragraphContent.type {
            XCTAssertEqual(name, EditorContent.Name.paragraph)
            XCTAssertEqual(attributedString.string, editorString.string)
        } else {
            XCTFail("Failed to get correct content [Paragraph]")
        }
        XCTAssertEqual(paragraphContent.enclosingRange, editorString.fullRange)

        let inlineAttachment = contents[1]
        if case let .attachment(name, contentView, type) = inlineAttachment.type {
            XCTAssertEqual(name, textField.name)
            XCTAssertEqual(contentView, textField)
            XCTAssertEqual(type, .inline)
        } else {
            XCTFail("Failed to get correct content [TextFieldAttachment]")
        }

        let spacerContent1 = contents[2]
        if case let .text(name, attributedString) = spacerContent1.type {
            XCTAssertEqual(name, EditorContent.Name.paragraph)
            XCTAssertEqual(attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines), "")
        } else {
            XCTFail("Failed to get correct content [Spacer]")
        }

        let blockAttachment = contents[3]
        if case let .attachment(name, contentView, type) = blockAttachment.type {
            XCTAssertEqual(name, panelView.name)
            XCTAssertEqual(contentView, panelView)
            XCTAssertEqual(type, .block)
        } else {
            XCTFail("Failed to get correct content [TextFieldAttachment]")
        }

        let spacerContent2 = contents[4]
        if case let .text(name, attributedString) = spacerContent2.type {
            XCTAssertEqual(name, EditorContent.Name.paragraph)
            XCTAssertEqual(attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines), "")
        } else {
            XCTFail("Failed to get correct content [Spacer]")
        }
    }

    func testGetsContentsByRange() {
        let editor = EditorView()
        let textField = AutogrowingTextField()
        let editorString = NSAttributedString(string: "Some text in Editor ")
        let attachmentString = NSAttributedString(string: "In full-width attachment")
        let attachment = Attachment(textField, size: .matchContent)
        textField.attributedText = attachmentString

        editor.replaceCharacters(in: .zero, with: editorString)
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        let contents = editor.contents(in: editorString.fullRange)

        XCTAssertEqual(contents.count, 1)
        let paragraphContent = contents[0]
        if case let .text(name, attributedString) = paragraphContent.type {
            XCTAssertEqual(name, EditorContent.Name.paragraph)
            XCTAssertEqual(attributedString.string, editorString.string)
        } else {
            XCTFail("Failed to get correct content [Paragraph]")
        }
        XCTAssertEqual(paragraphContent.enclosingRange, editorString.fullRange)
    }
}
