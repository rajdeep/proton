//
//  TextProcessorTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest

@testable import Proton

class TextProcessorTests: XCTestCase {
    func testRegistersTextProcessor() {
        let textProcessor = TextProcessor(editor: EditorView())
        let name = "RegsitrationTest"
        let mockProcessor = MockTextProcessor(name: name, processorCondition: { _, _ in return true })
        textProcessor.register(mockProcessor)

        XCTAssertEqual(textProcessor.sortedProcessors.count, 1)
        XCTAssertEqual(textProcessor.sortedProcessors[0].name, name)
    }

    func testUnregistersTextProcessor() {
        let textProcessor = TextProcessor(editor: EditorView())
        let name = "RegsitrationTest"
        let mockProcessor = MockTextProcessor(name: name, processorCondition: { _, _ in return true })
        textProcessor.register(mockProcessor)

        textProcessor.unregister(mockProcessor)

        XCTAssertEqual(textProcessor.sortedProcessors.count, 0)
    }

    func testInvokesTextProcessor() {
        let testExpectation = functionExpectation()
        let editor = EditorView()

        let name = "RegsitrationTest"
        let mockProcessor = MockTextProcessor(name: name, processorCondition: { _, _ in return true })
        mockProcessor.onProcess = { processedEditor, range, _ in
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

        let mockProcessor1 = MockTextProcessor(name: "p1", processorCondition: { _, _ in return true })
        mockProcessor1.priority = .high
        let mockProcessor2 = MockTextProcessor(name: "p2", processorCondition: { _, _ in return true })
        mockProcessor2.priority = .low

        var order = 0

        mockProcessor1.onProcess = { processedEditor, range, _ in
            XCTAssertEqual(order, 0)
            order += 1
            testExpectation.fulfill()
        }

        mockProcessor2.onProcess = { processedEditor, range, _ in
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

        let mockProcessor1 = MockTextProcessor(name: "e1", processorCondition: { _, _ in return true })
        mockProcessor1.priority = .exclusive
        let mockProcessor2 = MockTextProcessor(name: "p1", processorCondition: { _, _ in return true })
        mockProcessor2.priority = .medium

        mockProcessor2.onProcess = { processedEditor, range, _ in
            processExpectation.fulfill()
        }

        mockProcessor2.onProcessInterrupted = { _, range in
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
        editor.attributedText = NSAttributedString(string: "Test")
        let testAttribute = NSAttributedString.Key("testAttr")

        let processor: (EditorView, NSRange) -> Void = { editor, _ in
            let attrValue = editor.attributedText.attribute(testAttribute, at: 0, effectiveRange: nil) as? Int ?? 0
            editor.addAttribute(testAttribute, value: attrValue+1, at: editor.attributedText.fullRange)
            processorExpectation.fulfill()
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
}
