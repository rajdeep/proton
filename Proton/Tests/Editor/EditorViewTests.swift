//
//  EditorViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
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
import UIKit
import XCTest
import ProtonCore

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

        XCTAssertEqual(contents.count, 3)
        let paragraphContent = contents[0]
        if case let .text(name, attributedString) = paragraphContent.type {
            XCTAssertEqual(name, EditorContent.Name.paragraph)

            let paragraphContents = Array(attributedString.enumerateInlineContents())

            XCTAssertEqual(paragraphContents.count, 3)

            if case let .text(name, attributedString) = paragraphContents[0].type {
                XCTAssertEqual(name, EditorContent.Name.text)
                XCTAssertEqual(attributedString.string, editorString.string)
            } else {
                XCTFail("Failed to get correct content [Paragraph]")
            }

            let inlineAttachment = paragraphContents[1]
            if case let .attachment(name, attachment, contentView, type) = inlineAttachment.type {
                XCTAssertEqual(name, textField.name)
                XCTAssertEqual(attachment, textFieldAttachment)
                XCTAssertEqual(contentView, textField)
                XCTAssertEqual(type, .inline)
            } else {
                XCTFail("Failed to get correct content [TextFieldAttachment]")
            }

            let spacerContent1 = paragraphContents[2]
            if case let .text(name, attributedString) = spacerContent1.type {
                XCTAssertEqual(name, EditorContent.Name.text)
                XCTAssertEqual(attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines), "")
            } else {
                XCTFail("Failed to get correct content [Spacer]")
            }
        } else {
            XCTFail("Failed to get correct content [Paragraph]")
        }
        XCTAssertEqual(paragraphContent.enclosingRange, NSRange(location: 0, length: editorString.length + 2)) // string + inline attachment + spacer


        let blockAttachment = contents[1]
        if case let .attachment(name, attachment, contentView, type) = blockAttachment.type {
            XCTAssertEqual(name, panelView.name)
            XCTAssertEqual(attachment, panelAttachment)
            XCTAssertEqual(contentView, panelView)
            XCTAssertEqual(type, .block)
        } else {
            XCTFail("Failed to get correct content [TextFieldAttachment]")
        }

        let spacerContent2 = contents[2]
        if case let .text(name, attributedString) = spacerContent2.type {
            XCTAssertEqual(name, EditorContent.Name.newline)
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

    func testTransformsContents() {
        let editor = EditorView()
        let textField = AutogrowingTextField()
        let editorString = NSAttributedString(string: "Some text in Editor ")
        let attachmentString = NSAttributedString(string: "In full-width attachment")
        let attachment = Attachment(textField, size: .matchContent)
        textField.attributedText = attachmentString

        editor.replaceCharacters(in: .zero, with: editorString)
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)

        let transformedContents = editor.transformContents(using: TextEncoder())
        XCTAssertEqual(transformedContents.count, 1)

        let subContents = Array(transformedContents[0].split(separator: "\n"))
        XCTAssertEqual(subContents.count, 3)
        XCTAssertEqual(subContents[0], "Name: `\(EditorContent.Name.text.rawValue)` Text: `Some text in Editor `")
        XCTAssertEqual(subContents[1], "Name: `\(textField.name.rawValue)` ContentView: `AutogrowingTextField`")
        XCTAssertEqual(subContents[2], "Name: `\(EditorContent.Name.text.rawValue)` Text: ` `")
    }

    func testTransformsContentsSplitsParagraphs() {
        let editor = EditorView()
        let editorString = NSAttributedString(string: "\nSome text in Editor\nThis is second line")

        editor.replaceCharacters(in: .zero, with: editorString)

        let transformedContents = editor.transformContents(using: TextEncoder())
        XCTAssertEqual(transformedContents.count, 4)
        XCTAssertEqual(transformedContents[0], "Name: `\(EditorContent.Name.newline.rawValue)` Text: `\n`")
        XCTAssertEqual(transformedContents[1], "Name: `\(EditorContent.Name.text.rawValue)` Text: `Some text in Editor`")
        XCTAssertEqual(transformedContents[2], "Name: `\(EditorContent.Name.newline.rawValue)` Text: `\n`")
        XCTAssertEqual(transformedContents[3], "Name: `\(EditorContent.Name.text.rawValue)` Text: `This is second line`")
    }

    func testPropagatesAddAttributesToAttachments() {
        let attrExpectation = functionExpectation()
        let testString = "Test string"
        let editor = EditorView()
        let attachment = MockAttachment(PanelView(), size: .fixed(width: 50))
        let key = NSAttributedString.Key("TestKey")
        let attributesToAdd = [key: "value"]

        attachment.onAddedAttributesOnContainingRange = { range, attr in
            XCTAssertNotNil(attr[key] as? String)
            XCTAssertEqual(attributesToAdd[key], attr[key] as? String)
            XCTAssertEqual(range, attachment.rangeInContainer())
            attrExpectation.fulfill()
        }

        editor.replaceCharacters(in: .zero, with: testString)
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.addAttributes(attributesToAdd, at: NSRange(location: 7, length: editor.contentLength - 8))
        waitForExpectations(timeout: 1.0)
    }

    func testPropagatesRemoveAttributesToAttachments() {
        let attrExpectation = functionExpectation()
        let testString = "Test string"
        let editor = EditorView()
        let attachment = MockAttachment(PanelView(), size: .fixed(width: 50))
        let key = NSAttributedString.Key("TestKey")

        attachment.onRemovedAttributesFromContainingRange = { range, attr in
            XCTAssertFalse(attr.isEmpty)
            XCTAssertEqual(key, attr[0])
            XCTAssertEqual(range, attachment.rangeInContainer())
            attrExpectation.fulfill()
        }

        editor.replaceCharacters(in: .zero, with: testString)
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.removeAttribute(key, at: NSRange(location: 7, length: editor.contentLength - 8))
        waitForExpectations(timeout: 1.0)
    }

    func testSelectsAttachmentInSelectedRange() {
        let testExpectation = functionExpectation()

        let delegate = MockEditorViewDelegate()
        let editor = EditorView()
        editor.forceApplyAttributedText = true
        let attachment = Attachment(PanelView(), size: .fullWidth)
        let attrString = NSMutableAttributedString(string: "This is a test string")
        attrString.append(attachment.string)
        editor.attributedText = attrString

        editor.delegate = delegate
        XCTAssertFalse(attachment.isSelected)
        delegate.onSelectionChanged = { _, _, _, _ in
            XCTAssertTrue(attachment.isSelected)
            testExpectation.fulfill()
        }
        editor.selectedRange = editor.attributedText.fullRange
        waitForExpectations(timeout: 1.0)
    }

    func testGetsCurrentLineInformation() {
        let editor = EditorView()
        let line1 = NSAttributedString(string: "This is text in line 1\n")
        let line2 = NSAttributedString(string: "And this is text in line 2")
        editor.appendCharacters(line1)
        editor.appendCharacters(line2)
        editor.selectedRange = NSRange(location: line1.length + 4, length: 1)

        let currentLine = editor.currentLayoutLine
        XCTAssertEqual(currentLine?.text.string, line2.string)
        XCTAssertEqual(currentLine?.startsWith("And"), true)
        XCTAssertEqual(currentLine?.endsWith("line 2"), true)
    }

    func testReturnsZeroRangeForLineInEmptyEditor() {
        let editor = EditorView()
        let line = editor.currentLayoutLine
        XCTAssertEqual(line?.range, .zero)
    }

    func testReturnsNilForWordAtInvalidRange() {
        let editor = EditorView()
        let word = editor.word(at: 2)
        XCTAssertNil(word)
    }

    func testGetsWordAtLocation() {
        let editor = EditorView()
        editor.appendCharacters("This is a test line")
        let word = editor.word(at: 12)
        XCTAssertEqual(word?.string, "test")
    }

    func testReturnsIsAttachmentContentFalseByDefault() {
        let editor = EditorView()
        XCTAssertFalse(editor.isContainedInAnAttachment)
    }

    func testGetsIfEditorIsContainedInAnAttachment() {
        let panel = PanelView()
        let attachment = Attachment(panel, size: .matchContent)
        XCTAssertEqual(attachment.contentView, panel)
        XCTAssertTrue(panel.editor.isContainedInAnAttachment)
    }

    func testGetsContainerNameForEditorInAttachment() {
        let panel = PanelView()
        let attachment = Attachment(panel, size: .matchContent)
        XCTAssertEqual(attachment.contentView, panel)
        XCTAssertEqual(panel.editor.contentName, panel.name)
    }

    func testGetsContainerAttachment() {
        let panel = PanelView()
        let attachment = Attachment(panel, size: .matchContent)
        XCTAssertEqual(attachment.contentView, panel)
        XCTAssertEqual(panel.editor.containerAttachment, attachment)
    }

    func testGetsContainerContentName() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let panel = PanelView()
        let panelAttachment = Attachment(panel, size: .matchContent)
        editor.insertAttachment(in: .zero, attachment: panelAttachment)

        let textField = AutogrowingTextField()
        let textFieldAttachment = Attachment(textField, size: .matchContent)
        panel.editor.insertAttachment(in: .zero, attachment: textFieldAttachment)
        viewController.render()

        XCTAssertEqual(textFieldAttachment.containerContentName, panel.name)
    }

    func testGetsDefaultNestingLevel() {
        let panel = PanelView()
        XCTAssertEqual(panel.editor.nestingLevel, 0)
    }

    func testGetsNestingLevel() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let panel1 = PanelView()
        let panelAttachment1 = Attachment(panel1, size: .matchContent)
        editor.insertAttachment(in: .zero, attachment: panelAttachment1)

        let panel2 = PanelView()
        let panelAttachment2 = Attachment(panel2, size: .matchContent)
        panel1.editor.insertAttachment(in: .zero, attachment: panelAttachment2)

        let panel3 = PanelView()
        let panelAttachment3 = Attachment(panel3, size: .matchContent)
        panel2.editor.insertAttachment(in: .zero, attachment: panelAttachment3)

        viewController.render()

        XCTAssertEqual(editor.nestingLevel, 0)
        XCTAssertEqual(panel1.editor.nestingLevel, 1)
        XCTAssertEqual(panel2.editor.nestingLevel, 2)
        XCTAssertEqual(panel3.editor.nestingLevel, 3)
    }

    func testRegisteredCommandsIsNilByDefault() {
        let editor = EditorView()
        XCTAssertNil(editor.registeredCommands)
    }

    func testRegisteredCommandsIsNotNilWhenCommandIsRegistered() {
        let editor = EditorView()
        let command = MockEditorCommand { _ in }
        editor.registerCommand(command)
        XCTAssertNotNil(editor.registeredCommands)
    }

    func testSetsRegisteredCommandsToNilWhenAllCommandRegisterationsAreRemoved() {
        let editor = EditorView()
        let command = MockEditorCommand { _ in }
        editor.registerCommand(command)
        editor.unregisterCommand(command)
        XCTAssertNil(editor.registeredCommands)
    }

    func testRegistersCommands() {
        let editor = EditorView()
        let command = MockEditorCommand { _ in }
        editor.registerCommand(command)

        XCTAssertEqual(editor.registeredCommands?.count, 1)
        XCTAssertTrue(editor.registeredCommands?.contains{ $0 === command } ?? false)
    }

    func testUnregistersCommands() {
        let editor = EditorView()
        let command1 = MockEditorCommand(name: "command1") { _ in }
        let command2 = MockEditorCommand(name: "command2")  { _ in }
        editor.registerCommand(command1)
        editor.registerCommand(command2)

        editor.unregisterCommand(command1)
        XCTAssertEqual(editor.registeredCommands?.count, 1)
        XCTAssertTrue(editor.registeredCommands?.contains{ $0.name == command2.name } ?? false)
    }

    func testReturnsNilForInvalidNextLine() throws {
        let editor = EditorView()
        editor.forceApplyAttributedText = true
        let attrString = NSMutableAttributedString(string: "This is a test string")
        editor.attributedText = attrString

        let currentLine = try XCTUnwrap(editor.currentLayoutLine)
        XCTAssertEqual(currentLine.text.string, attrString.string)
        XCTAssertNil(editor.layoutLineAfter(currentLine))
    }

    func testReturnsNilForInvalidPreviousLine() throws {
        let editor = EditorView()
        editor.forceApplyAttributedText = true
        let attrString = NSMutableAttributedString(string: "This is a test string")
        editor.attributedText = attrString

        let currentLine = try XCTUnwrap(editor.currentLayoutLine)
        XCTAssertEqual(currentLine.text.string, attrString.string)
        XCTAssertNil(editor.layoutLineBefore(currentLine))
    }

    func testResetsAttributesWhenCleared() {
        let editor = EditorView()
        editor.forceApplyAttributedText = true
        editor.textColor = UIColor.red
        let attrString = NSMutableAttributedString(string: "This is a test string", attributes: [.foregroundColor: UIColor.blue])
        editor.attributedText = attrString
        editor.clear()
        editor.appendCharacters(NSAttributedString(string: "test"))
        let color = editor.attributedText.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertEqual(color, editor.textColor)
    }

    func testNotifiesEditorDelegateOfExecutedProcessors() {
        let testExpectation = functionExpectation()
        let editor = EditorView()
        let delegate = MockEditorViewDelegate()
        editor.delegate = delegate

        let name1 = "TextProcessorTest1"
        let name2 = "TextProcessorTest2"
        let name3 = "TextProcessorTest3"

        let mockProcessor1 = MockTextProcessor(name: name1)
        let mockProcessor2 = MockTextProcessor(name: name2, processorCondition: { _, _ in false })
        let mockProcessor3 = MockTextProcessor(name: name3)

        editor.registerProcessors([mockProcessor1, mockProcessor2, mockProcessor3])

        delegate.onDidExecuteProcessors = { _, processors, range in
            XCTAssertEqual(processors.count, 2)
            XCTAssertEqual(processors[0].name, name1)
            XCTAssertEqual(processors[1].name, name3)
            XCTAssertEqual(range, editor.attributedText.fullRange)
            testExpectation.fulfill()
        }

        editor.appendCharacters("test")
        waitForExpectations(timeout: 1.0)
    }

    func testRegistersUniqueCommands() throws {
        let command1 = MockEditorCommand(name: "set1") { _ in  }
        let command2 = MockEditorCommand(name: "set1") { _ in  }
        let command3 = MockEditorCommand(name: "set2") { _ in  }
        let command4 = MockEditorCommand(name: "set2") { _ in  }

        let editor = EditorView()
        editor.registerCommands([command1, command2])

        editor.registerCommand(command3)
        editor.registerCommand(command4)

        let registeredCommands = try XCTUnwrap(editor.registeredCommands)

        XCTAssertEqual(registeredCommands.count, 2)
        XCTAssertTrue(registeredCommands[0] === command2)
        XCTAssertTrue(registeredCommands[1] === command4)
    }

    func testGetsContentLinesInRangeContainingNoNewline() {
        let editor = EditorView()
        let line1 = "Line 1"
        editor.appendCharacters(NSAttributedString(string: line1))
        let lines = editor.contentLinesInRange(editor.attributedText.fullRange)

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text.string, line1)
    }

    func testGetsContentLinesInZeroLengthRange() {
        let editor = EditorView()
        let line1 = "Line 1"
        editor.appendCharacters(NSAttributedString(string: line1))
        let lines = editor.contentLinesInRange(NSRange(location: 3, length: 0))

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text.string, line1)
    }

    func testGetsContentLinesInRange() {
        let editor = EditorView()
        let line1 = "Line 1"
        let line2 = "Line 2"
        let line3 = "Line 3"

        editor.appendCharacters(NSAttributedString(string: line1))
        editor.appendCharacters(NSAttributedString(string: "\n"))
        editor.appendCharacters(NSAttributedString(string: line2))
        editor.appendCharacters(NSAttributedString(string: "\n"))
        editor.appendCharacters(NSAttributedString(string: line3))

        let lines = editor.contentLinesInRange(editor.attributedText.fullRange)

        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].text.string, line1)
        XCTAssertEqual(lines[1].text.string, line2)
        XCTAssertEqual(lines[2].text.string, line3)
    }

    func testGetsPreviousLineFromLocation() {
        let editor = EditorView()
        let line1 = "Line 1"
        let line2 = "Line 2"

        editor.appendCharacters(NSAttributedString(string: line1))
        editor.appendCharacters(NSAttributedString(string: "\n"))
        editor.appendCharacters(NSAttributedString(string: line2))

        let previousLine = editor.previousContentLine(from: 7)
        XCTAssertEqual(previousLine?.text.string, line1)
    }

    func testGetsPreviousLineFromLocationWithNoPrecedingNewline() {
        let editor = EditorView()
        let line1 = "Line 1"

        editor.appendCharacters(NSAttributedString(string: line1))
        let previousLine = editor.previousContentLine(from: 3)
        XCTAssertNil(previousLine)
    }

    func testGetsNextLineFromLocation() {
        let editor = EditorView()
        let line1 = "Line 1"
        let line2 = "Line 2"

        editor.appendCharacters(NSAttributedString(string: line1))
        editor.appendCharacters(NSAttributedString(string: "\n"))
        editor.appendCharacters(NSAttributedString(string: line2))

        let nextLine = editor.nextContentLine(from: 3)
        XCTAssertEqual(nextLine?.text.string, line2)
    }

    func testGetsNextLineFromLocationWithNoEndingNewLine() {
        let editor = EditorView()
        let line1 = "Line 1"

        editor.appendCharacters(NSAttributedString(string: line1))
        let nextLine = editor.nextContentLine(from: 3)
        XCTAssertNil(nextLine)
    }

    func testNotifiesDelegateOfSizeChanges() {
        let testExpectation = functionExpectation()

        let delegate = MockEditorViewDelegate()
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        editor.delegate = delegate

        delegate.onDidChangeSize  = { _, currentSize, previousSize in
            XCTAssertEqual(previousSize, .zero)
            XCTAssertNotEqual(currentSize, .zero)
            testExpectation.fulfill()
        }

        let attrString = NSMutableAttributedString(string: "This is a test string")
        editor.attributedText = attrString
        viewController.render()

        waitForExpectations(timeout: 1.0)
    }
        
    func testCaretRect() {
        let editor = EditorView()
        let yOffset: CGFloat = 50
        editor.contentOffset = .init(x: 0, y: yOffset)
        let cursorRect = editor.caretRect(for: 0)
        XCTAssertEqual(cursorRect.origin.y, editor.textContainerInset.top - yOffset)
    }

    func testRangeInContainerForImageBasedAttachment() throws {
        let editor = EditorView()
        let image = AttachmentImage(name: EditorContentName("image"), image: UIImage(systemName: "car")!, size: CGSize(width: 40, height: 40), type: .inline)
        let attachment = Attachment(image: image)

        editor.replaceCharacters(in: .zero, with: "In textView ")
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        editor.replaceCharacters(in: editor.textEndRange, with: "Text after attachment")

        let range = try XCTUnwrap(attachment.rangeInContainer())
        XCTAssertEqual(range, NSRange(location: 12, length: 1))

    }

    func testGetsRootEditor() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let panel1 = PanelView()
        let panelAttachment1 = Attachment(panel1, size: .matchContent)
        editor.insertAttachment(in: .zero, attachment: panelAttachment1)

        let panel2 = PanelView()
        let panelAttachment2 = Attachment(panel2, size: .matchContent)
        panel1.editor.insertAttachment(in: .zero, attachment: panelAttachment2)

        let panel3 = PanelView()
        let panelAttachment3 = Attachment(panel3, size: .matchContent)
        panel2.editor.insertAttachment(in: .zero, attachment: panelAttachment3)

        viewController.render()

        XCTAssertEqual(editor.rootEditor, editor)
        XCTAssertEqual(panel1.editor.rootEditor, editor)
        XCTAssertEqual(panel2.editor.rootEditor, editor)
    }

    func testGetsParentEditor() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let panel1 = PanelView()
        let panelAttachment1 = Attachment(panel1, size: .matchContent)
        editor.insertAttachment(in: .zero, attachment: panelAttachment1)

        let panel2 = PanelView()
        let panelAttachment2 = Attachment(panel2, size: .matchContent)
        panel1.editor.insertAttachment(in: .zero, attachment: panelAttachment2)

        let panel3 = PanelView()
        let panelAttachment3 = Attachment(panel3, size: .matchContent)
        panel2.editor.insertAttachment(in: .zero, attachment: panelAttachment3)

        viewController.render()

        XCTAssertNil(editor.parentEditor)
        XCTAssertEqual(panel1.editor.parentEditor, editor)
        XCTAssertEqual(panel2.editor.parentEditor, panel1.editor)
    }

    func testGetsAttachmentContentEditors() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let dummyAttachment1 = DummyMultiEditorAttachment(numberOfEditors: 1)
        editor.insertAttachment(in: .zero, attachment: dummyAttachment1)

        let dummyAttachment2 = DummyMultiEditorAttachment(numberOfEditors: 2)
        editor.insertAttachment(in: editor.textEndRange, attachment: dummyAttachment2)

        viewController.render()

        XCTAssertEqual(dummyAttachment1.contentEditors.count, 1)
        XCTAssertEqual(dummyAttachment2.contentEditors.count, 2)
    }

    func testGetsFullAttributedText() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        editor.attributedText = NSAttributedString(string: "Text before panel 1")

        let panel1 = PanelView()
        panel1.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 1"))
        let panelAttachment1 = Attachment(panel1, size: .matchContent)
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment1)

        editor.replaceCharacters(in: editor.textEndRange, with: NSAttributedString(string: "Text after panel 1"))

        let panel2 = PanelView()
        panel2.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 2"))
        let panelAttachment2 = Attachment(panel2, size: .matchContent)
        panel1.editor.insertAttachment(in: panel1.editor.textEndRange, attachment: panelAttachment2)

        let panel3 = PanelView()
        panel3.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 3"))
        let panelAttachment3 = Attachment(panel3, size: .matchContent)
        panel2.editor.insertAttachment(in: panel2.editor.textEndRange, attachment: panelAttachment3)

        viewController.render()

        let attachmentContentIdentifier = AttachmentContentIdentifier(openingID: NSAttributedString(string: "["), closingID: NSAttributedString(string: "]"))

        let text = editor.getFullAttributedText(using: attachmentContentIdentifier)
        let expectedString = "Text before panel 1[Text inside panel 1[Text inside panel 2[Text inside panel 3]\n]\n]\nText after panel 1"
        XCTAssertEqual(text.string, expectedString)
    }

    func testAttachmentsInRangeWithValidRange() {
            let editor = EditorView()

            let panel1 = PanelView()
            panel1.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 1"))
            let panelAttachment1 = Attachment(panel1, size: .matchContent)
            editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment1)

            let panel2 = PanelView()
            panel2.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 2"))
            let panelAttachment2 = Attachment(panel2, size: .matchContent)
            editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment2)

            let attachments = editor.attachmentsInRange(NSRange(location: editor.attributedText.length - 2, length: 2))
            XCTAssertEqual(attachments.count, 1)
        }

    func testGetsFullAttributedTextFromRange() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        editor.attributedText = NSAttributedString(string: "Text before panel 1")

        let panel1 = PanelView()
        panel1.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 1"))
        let panelAttachment1 = Attachment(panel1, size: .matchContent)
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment1)

        editor.replaceCharacters(in: editor.textEndRange, with: NSAttributedString(string: "Text after panel 1"))

        let panel2 = PanelView()
        panel2.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 2"))
        let panelAttachment2 = Attachment(panel2, size: .matchContent)
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment2)

        let panel3 = PanelView()
        panel3.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 3"))
        let panelAttachment3 = Attachment(panel3, size: .matchContent)
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment3)

        editor.selectedRange = NSRange(location: 5, length: 15)

        viewController.render()

        let attachmentContentIdentifier = AttachmentContentIdentifier(openingID: NSAttributedString(string: "["), closingID: NSAttributedString(string: "]"))

        let text = editor.getFullAttributedText(using: attachmentContentIdentifier, in: editor.selectedRange)
        let expectedString = "before panel 1[Text inside panel 1]"
        XCTAssertEqual(text.string, expectedString)
    }

    func testGetsRangeForAttributeAtLocation() {
        let editor = EditorView()
        let customAttribute = NSAttributedString.Key("_custom")
        editor.replaceCharacters(in: editor.textEndRange, with: NSAttributedString(string: "This is some text with attributes"))
        editor.addAttributes([
            customAttribute: UIColor.red
        ], at: NSRange(location: 6, length: 4))

        editor.addAttributes([
            customAttribute: UIColor.red
        ], at: NSRange(location: 12, length: 4))

        let range1 = editor.attributeRangeFor(customAttribute, at: 2)
        XCTAssertNil(range1)
        let range2 = editor.attributeRangeFor(customAttribute, at: 8)
        XCTAssertEqual(range2, NSRange(location: 6, length: 4))
        let range3 = editor.attributeRangeFor(customAttribute, at: 11)
        XCTAssertNil(range3)
        let range4 = editor.attributeRangeFor(customAttribute, at: 15)
        XCTAssertEqual(range4, NSRange(location: 12, length: 4))
    }

    func testNotifiedOfIsEditableChanges() {
        let testExpectation = functionExpectation()
        let delegate = MockEditorViewDelegate()
        let editor = EditorView()
        editor.delegate = delegate
        XCTAssertTrue(editor.isEditable)

        delegate.onDidChangeEditable = { _, isEditable in
            XCTAssertFalse(isEditable)
            testExpectation.fulfill()
        }
        editor.isEditable = false
        waitForExpectations(timeout: 1.0)
    }

    func testGetsNestedEditors() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        editor.attributedText = NSAttributedString(string: "Text before panel 1")

        let panel1 = PanelView()
        panel1.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 1"))
        let panelAttachment1 = Attachment(panel1, size: .matchContent)
        editor.insertAttachment(in: editor.textEndRange, attachment: panelAttachment1)

        editor.replaceCharacters(in: editor.textEndRange, with: NSAttributedString(string: "Text after panel 1"))

        let panel2 = PanelView()
        panel2.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 2 (parent panel 1)"))
        let panelAttachment2 = Attachment(panel2, size: .matchContent)
        panel1.editor.insertAttachment(in: panel1.editor.textEndRange, attachment: panelAttachment2)

        let panel3 = PanelView()
        panel3.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 3 (parent panel 2)"))
        let panelAttachment3 = Attachment(panel3, size: .matchContent)
        panel2.editor.insertAttachment(in: panel2.editor.textEndRange, attachment: panelAttachment3)

        let panel4 = PanelView()
        panel4.editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Text inside panel 4 (parent panel 2)"))
        let panelAttachment4 = Attachment(panel4, size: .matchContent)
        panel2.editor.insertAttachment(in: panel2.editor.textEndRange, attachment: panelAttachment4)

        let nestedEditorsTexts = editor.nestedEditors.map { $0.text }

        XCTAssertEqual(nestedEditorsTexts[0], panel1.editor.text)
        XCTAssertEqual(nestedEditorsTexts[1], panel2.editor.text)
        XCTAssertEqual(nestedEditorsTexts[2], panel3.editor.text)
        XCTAssertEqual(nestedEditorsTexts[3], panel4.editor.text)

    }

    func testContentLineAtBeginningAndEnd() {
        let editor = EditorView()
        let line1 = "line 1\n"
        editor.replaceCharacters(in: .zero, with: NSAttributedString(string: line1))

        let linesAtBeginning = editor.contentLinesInRange(.zero)

        XCTAssertEqual(linesAtBeginning.count, 1)
        XCTAssertEqual(linesAtBeginning[0].text.string, "line 1")

        let linesAtEnd = editor.contentLinesInRange(NSRange(location: 7, length: 0))

        XCTAssertEqual(linesAtEnd.count, 1)
        XCTAssertTrue(linesAtEnd[0].text.string.isEmpty)

        let linesOutsideRange = editor.contentLinesInRange(NSRange(location: 8, length: 0))
        XCTAssertEqual(linesOutsideRange.count, 0)
    }

    func testEnsuresCorrectSelectedRangeOnReplace() {
        let editor = EditorView()
        editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test"))
        let lastCharRange = NSRange(location: 3, length: 1)
        editor.selectedRange = lastCharRange
        editor.replaceCharacters(in: lastCharRange, with: NSAttributedString(string: ""))
        XCTAssertTrue(editor.richTextView.selectedRange.isValidIn(editor.richTextView))
        XCTAssertEqual(editor.selectedRange, NSRange(location: 3, length: 0))
    }

    func testAttachmentsInRangeWithInvalidRange() {
        let editor = EditorView()
        editor.replaceCharacters(in: .zero, with: NSAttributedString(string: "Test"))
        editor.attributedText = NSAttributedString(string: "In")
        _ = editor.attachmentsInRange(NSRange(location: 2, length: 1))
        XCTAssertEqual(editor.attributedText.length, 2)
    }

    func testRemovesContainerEditorOnDeletingAttachment() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let dummyAttachment1 = DummyMultiEditorAttachment(numberOfEditors: 1)
        editor.insertAttachment(in: .zero, attachment: dummyAttachment1)

        let dummyAttachment2 = DummyMultiEditorAttachment(numberOfEditors: 2)
        editor.insertAttachment(in: editor.textEndRange, attachment: dummyAttachment2)

        viewController.render()

        XCTAssertEqual(dummyAttachment1.containerEditorView, editor)
        XCTAssertEqual(dummyAttachment2.containerEditorView, editor)

        editor.replaceCharacters(in: NSRange(location: 0, length: 1), with: NSAttributedString())
        dummyAttachment2.removeFromContainer()

        XCTAssertNil(dummyAttachment1.containerEditorView)
        XCTAssertNil(dummyAttachment2.containerEditorView)
    }

    func testPreservesNewlineBeforeAttachmentOnDelete() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.preserveBlockAttachmentNewline = .before

        let testString = NSAttributedString(string: "test string\n")
        editor.replaceCharacters(in: .zero, with: testString)
        let attachment = makePanelAttachment()
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        XCTAssertEqual(editor.text, "test string\n￼\n")

        editor.replaceCharacters(in: NSRange(location: 8, length: 4), with: "")
        XCTAssertEqual(editor.attachmentsInRange(editor.attributedText.fullRange).first?.range, NSRange(location: 9, length: 1))

        XCTAssertEqual(editor.text, "test str\n￼\n")
    }

    func testPreservesNewlineAfterAttachmentOnDelete() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.preserveBlockAttachmentNewline = .after

        let testString = NSAttributedString(string: "test string\n  After attachment")
        editor.replaceCharacters(in: .zero, with: testString)
        let attachment = makePanelAttachment()
        editor.insertAttachment(in: NSRange(location: 13, length: 0), attachment: attachment)

        editor.replaceCharacters(in: NSRange(location: 14, length: 7), with: "")

        XCTAssertEqual(editor.text, "test string\n ￼\n attachment")
        XCTAssertEqual(editor.attachmentsInRange(editor.attributedText.fullRange).first?.range, NSRange(location: 13, length: 1))
    }

    func testDoesNotPreservesNewlineByDefault() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let testString = NSAttributedString(string: "test string\n")
        editor.replaceCharacters(in: .zero, with: testString)
        let attachment = makePanelAttachment()
        editor.insertAttachment(in: editor.textEndRange, attachment: attachment)
        XCTAssertEqual(editor.text, "test string\n￼\n")

        editor.replaceCharacters(in: NSRange(location: 8, length: 4), with: "")

        XCTAssertEqual(editor.text, "test str￼\n")
        XCTAssertEqual(editor.attachmentsInRange(editor.attributedText.fullRange).first?.range, NSRange(location: 8, length: 1))
    }
}


func makePanelAttachment() -> Attachment {
    let panel = PanelView()
    panel.editor.forceApplyAttributedText = true
    panel.backgroundColor = .cyan
    panel.layer.borderWidth = 1.0
    panel.layer.cornerRadius = 4.0
    panel.layer.borderColor = UIColor.black.cgColor

    return Attachment(panel, size: .fullWidth)
}


class DummyMultiEditorAttachment: Attachment {
    let view: DummyMultiEditorView
    init(numberOfEditors: Int) {
        view = DummyMultiEditorView(numberOfEditors: numberOfEditors)
        super.init(view, size: .fullWidth)
    }
}

class DummyMultiEditorView: AttachmentView {
    var type: Proton.AttachmentType { .block }
    var name: Proton.EditorContent.Name { .init("dummy") }

    var contentEditors = [EditorView]()

    init(numberOfEditors: Int) {
        for i in 0..<numberOfEditors {
            let editor = EditorView()
            editor.attributedText = NSAttributedString(string: "\(i)")
            contentEditors.append(editor)
        }
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 300, height: 40)))
        contentEditors.forEach { addSubview($0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
