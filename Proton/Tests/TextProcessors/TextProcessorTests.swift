//
//  TextProcessorTests.swift
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
import XCTest

@testable import Proton

class TextProcessorTests: XCTestCase {
    func testRegistersTextProcessor() {
        let textProcessor = TextProcessor(editor: EditorView())
        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        textProcessor.register(mockProcessor)

        XCTAssertEqual(textProcessor.sortedProcessors.count, 1)
        XCTAssertEqual(textProcessor.sortedProcessors[0].name, name)
    }

    func testUnregistersTextProcessor() {
        let textProcessor = TextProcessor(editor: EditorView())
        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        textProcessor.register(mockProcessor)

        textProcessor.unregister(mockProcessor)

        XCTAssertEqual(textProcessor.sortedProcessors.count, 0)
    }

    func testInvokesWillProcess() throws {
        let testExpectation = functionExpectation()
        let editor = EditorView()
        let richTextEditorContext = try XCTUnwrap(editor.context as? RichTextEditorContext)

        let name = "TextProcessorTest"
        let replacementString = NSAttributedString(string: "replacement string")
        let mockProcessor = MockTextProcessor(name: name)
        let replacementRange = NSRange(location: 5, length: 4)

        mockProcessor.onWillProcess = { editorView, deleted, inserted, range in
            XCTAssertEqual(editorView, editor)
            XCTAssertEqual(deleted.string, "some")
            XCTAssertEqual(inserted.string, replacementString.string)
            XCTAssertEqual(range, replacementRange)
            testExpectation.fulfill()
        }

        richTextEditorContext.textViewDidBeginEditing(editor.richTextView)
        let testString = NSAttributedString(string: "test some text")

        editor.replaceCharacters(in: .zero, with: testString)
        editor.registerProcessor(mockProcessor)

        editor.replaceCharacters(in: replacementRange, with: replacementString)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesTextProcessor() {
        let testExpectation = functionExpectation()
        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.onProcess = { processedEditor, _, _ in
            XCTAssertEqual(processedEditor, editor)
            testExpectation.fulfill()
        }
        let testString = NSAttributedString(string: "test")
        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesTextProcessorInPriorityOrder() {
        let testExpectation = functionExpectation()
        testExpectation.expectedFulfillmentCount = 2

        let editor = EditorView()

        let mockProcessor1 = MockTextProcessor(name: "p1")
        mockProcessor1.priority = .high
        let mockProcessor2 = MockTextProcessor(name: "p2")
        mockProcessor2.priority = .low

        var order = 0

        mockProcessor1.onProcess = { _, _, _ in
            XCTAssertEqual(order, 0)
            order += 1
            testExpectation.fulfill()
        }

        mockProcessor2.onProcess = { _, _, _ in
            XCTAssertEqual(order, 1)
            order += 1
            testExpectation.fulfill()
        }

        let testString = NSAttributedString(string: "test")

        editor.registerProcessor(mockProcessor1)
        editor.registerProcessor(mockProcessor2)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesProcessInterruptedForExclusiveProcessor() {
        let processExpectation = functionExpectation("process")
        processExpectation.isInverted = true

        let interruptExpectation = functionExpectation("interrupt")

        let editor = EditorView()

        let mockProcessor1 = MockTextProcessor(name: "e1")
        mockProcessor1.priority = .exclusive
        let mockProcessor2 = MockTextProcessor(name: "p1")
        mockProcessor2.priority = .medium

        mockProcessor2.onProcess = { _, _, _ in
            processExpectation.fulfill()
        }

        mockProcessor2.onProcessInterrupted = { _, _ in
            interruptExpectation.fulfill()
        }

        let testString = NSAttributedString(string: "test")
        editor.registerProcessor(mockProcessor1)
        editor.registerProcessor(mockProcessor2)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }

    func testAppliesChangesFromAllProcessors() {
        let processorExpectation = functionExpectation()
        processorExpectation.expectedFulfillmentCount = 3

        let editor = EditorView()
        editor.forceApplyAttributedText = true
        editor.attributedText = NSAttributedString(string: "Test")
        let testAttribute = NSAttributedString.Key("testAttr")

        let processor: (EditorView, NSRange) -> Processed = { editor, _ in
            let attrValue = editor.attributedText.attribute(testAttribute, at: 0, effectiveRange: nil) as? Int ?? 0
            editor.addAttribute(testAttribute, value: attrValue + 1, at: editor.attributedText.fullRange)
            processorExpectation.fulfill()
            return true
        }

        let processor1 = TestTextProcessor()
        processor1.onProcess = processor
        let processor2 = TestTextProcessor()
        processor2.onProcess = processor
        let processor3 = TestTextProcessor()
        processor3.onProcess = processor

        editor.registerProcessor(processor1)
        editor.registerProcessor(processor2)
        editor.registerProcessor(processor3)

        editor.replaceCharacters(in: editor.textEndRange, with: NSAttributedString(string: " string"))
        let attrValue = editor.attributedText.attribute(testAttribute, at: 0, effectiveRange: nil) as? Int ?? 0
        XCTAssertEqual(attrValue, 3)

        waitForExpectations(timeout: 1.0)
    }

    func testGetsNotifiedOfSelectedRangeChanges() {
        let testExpectation = functionExpectation()
        let editor = EditorView()
        editor.forceApplyAttributedText = true
        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        let originalRange = NSRange(location: 2, length: 1)
        let rangeToSet = NSRange(location: 5, length: 4)
        editor.attributedText = NSAttributedString(string: "This is a test")

        editor.richTextView.selectedTextRange = originalRange.toTextRange(textInput: editor.richTextView)

        mockProcessor.onSelectedRangeChanged = { _, old, new in
            XCTAssertEqual(old, originalRange)
            XCTAssertEqual(new, rangeToSet)
            testExpectation.fulfill()
        }

        editor.registerProcessor(mockProcessor)
        editor.richTextView.selectedTextRange = rangeToSet.toTextRange(textInput: editor.richTextView)
        waitForExpectations(timeout: 1.0)
    }

    func testProcessesEnterKey() {
        let testExpectation = functionExpectation()
        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.onKeyWithModifier = {_, key, _, range in
            XCTAssertEqual(key, .enter)
            XCTAssertEqual(range, NSRange(location: 5, length: 1))
            testExpectation.fulfill()
        }

        editor.registerProcessor(mockProcessor)
        editor.appendCharacters(NSAttributedString(string: "test "))
        editor.appendCharacters("\n")

        waitForExpectations(timeout: 1.0)
    }

    func testProcessesTabKey() {
        let testExpectation = functionExpectation()
        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.onKeyWithModifier = {_, key, _, range in
            XCTAssertEqual(key, .tab)
            XCTAssertEqual(range, NSRange(location: 5, length: 1))
            testExpectation.fulfill()
        }

        editor.registerProcessor(mockProcessor)
        editor.appendCharacters(NSAttributedString(string: "test "))
        editor.appendCharacters("\t")

        waitForExpectations(timeout: 1.0)
    }

    func testDidProcess() {
        let testExpectation = functionExpectation()
        let editor = EditorView()
        let text = NSAttributedString(string: "test ")

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.onDidProcess = { editor in
            XCTAssertEqual(editor.attributedText.string, text.string)
            testExpectation.fulfill()
        }

        editor.registerProcessor(mockProcessor)
        editor.appendCharactersForTest(text)

        waitForExpectations(timeout: 1.0)
    }

    func testShouldProcess() {
        let testExpectation = functionExpectation()
        testExpectation.isInverted = true

        let editor = EditorView()
        let text = NSAttributedString(string: "test ")

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.onShouldProcess = { _, _, _ in
            return false
        }

        mockProcessor.onDidProcess = { editor in
            testExpectation.fulfill()
        }

        editor.registerProcessor(mockProcessor)
        editor.appendCharactersForTest(text)

        waitForExpectations(timeout: 1.0)
    }

    func testShouldProcessMultipleProcessors() {
        let testExpectation1 = functionExpectation("1")
        let testExpectation2 = functionExpectation("2")
        let didProcessExpectation = functionExpectation("didProcess")

        didProcessExpectation.isInverted = true

        let editor = EditorView()
        let text = NSAttributedString(string: "test ")

        let name1 = "TextProcessorTest1"
        let name2 = "TextProcessorTest2"

        let mockProcessor1 = MockTextProcessor(name: name1)
        let mockProcessor2 = MockTextProcessor(name: name2)

        mockProcessor1.onShouldProcess = { _, _, _ in
            testExpectation1.fulfill()
            return true
        }

        mockProcessor2.onShouldProcess = { _, _, _ in
            testExpectation2.fulfill()
            return false
        }

        mockProcessor1.onDidProcess = { _ in
            didProcessExpectation.fulfill()
        }

        mockProcessor2.onDidProcess = { _ in
            didProcessExpectation.fulfill()
        }

        editor.registerProcessors([mockProcessor1, mockProcessor2])
        editor.appendCharactersForTest(text)

        waitForExpectations(timeout: 1.0)
    }

    func testInvokesWillProcessEditingContent() {
        let testExpectation = functionExpectation()

        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.willProcessEditing = { processedEditor, editingMask, range, delta in
            XCTAssertEqual(processedEditor, editor)
            XCTAssertTrue(editingMask.contains(.editedAttributes))
            XCTAssertTrue(editingMask.contains(.editedCharacters))
            XCTAssertEqual(range, editor.attributedText.fullRange)
            XCTAssertEqual(delta, editor.contentLength)
            testExpectation.fulfill()
        }
        let testString = NSAttributedString(string: "test")
        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesDidProcessEditingContent() {
        let testExpectation = functionExpectation()

        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.didProcessEditing = { processedEditor, editingMask, range, delta in
            XCTAssertEqual(processedEditor, editor)
            XCTAssertTrue(editingMask.contains(.editedAttributes))
            XCTAssertTrue(editingMask.contains(.editedCharacters))
            XCTAssertEqual(range, editor.attributedText.fullRange)
            XCTAssertEqual(delta, editor.contentLength)
            testExpectation.fulfill()
        }
        let testString = NSAttributedString(string: "test")
        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesDidProcessEditingContentOnPartialDelete() {
        let testExpectation = functionExpectation()

        let editor = EditorView()
        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.didProcessEditing = { processedEditor, editingMask, range, delta in
            XCTAssertEqual(processedEditor, editor)
            XCTAssertTrue(editingMask.contains(.editedAttributes))
            XCTAssertTrue(editingMask.contains(.editedCharacters))
            XCTAssertEqual(delta, -2)
            testExpectation.fulfill()
        }
        let testString = NSAttributedString(string: "test")
        editor.replaceCharacters(in: .zero, with: testString)
        editor.registerProcessor(mockProcessor)
        let processRange = NSRange(location: 2, length: 2)
        editor.replaceCharacters(in: processRange, with: NSAttributedString())
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesDidProcessEditingContentOnFullDelete() {
        let testExpectation = functionExpectation()

        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)
        mockProcessor.didProcessEditing = { processedEditor, editingMask, range, delta in
            XCTAssertEqual(processedEditor, editor)
            XCTAssertTrue(editingMask.contains(.editedAttributes))
            XCTAssertTrue(editingMask.contains(.editedCharacters))
            XCTAssertEqual(delta, -4)
            testExpectation.fulfill()
        }
        let testString = NSAttributedString(string: "test")
        editor.replaceCharacters(in: .zero, with: testString)
        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: editor.attributedText.fullRange, with: NSAttributedString())
        waitForExpectations(timeout: 1.0)
    }

    func testInvokesWillProcessAttributeChanges() {
        let testExpectation = functionExpectation()

        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)

        let testString = NSAttributedString(string: "test")
        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)

        let processRange = NSRange(location: 2, length: 2)
        mockProcessor.willProcessEditing = { processedEditor, editingMask, range, delta in
            XCTAssertTrue(editingMask.contains(.editedAttributes))
            XCTAssertFalse(editingMask.contains(.editedCharacters))
            XCTAssertEqual(range, processRange)
            testExpectation.fulfill()
        }

        editor.selectedRange = processRange
        BoldCommand().execute(on: editor)

        waitForExpectations(timeout: 1.0)
    }

    func testInvokesDidProcessAttributeChanges() {
        let testExpectation = functionExpectation()

        let editor = EditorView()

        let name = "TextProcessorTest"
        let mockProcessor = MockTextProcessor(name: name)

        let testString = NSAttributedString(string: "test")
        editor.registerProcessor(mockProcessor)
        editor.replaceCharacters(in: .zero, with: testString)

        let processRange = NSRange(location: 2, length: 2)
        mockProcessor.didProcessEditing = { processedEditor, editingMask, range, delta in
            XCTAssertTrue(editingMask.contains(.editedAttributes))
            XCTAssertFalse(editingMask.contains(.editedCharacters))
            XCTAssertEqual(range, processRange)
            testExpectation.fulfill()
        }

        editor.selectedRange = processRange
        BoldCommand().execute(on: editor)

        waitForExpectations(timeout: 1.0)
    }
}

extension EditorView {
    func appendCharactersForTest(_ text: NSAttributedString) {
        guard let textViewDelegate = richTextView.delegate else { return }
        textViewDelegate.textViewDidBeginEditing?(richTextView)

        if textViewDelegate.textView?(richTextView, shouldChangeTextIn: richTextView.textEndRange, replacementText: text.string) == false {
            return
        }

        appendCharacters(text)
        textViewDelegate.textViewDidChange?(richTextView)
    }
}
