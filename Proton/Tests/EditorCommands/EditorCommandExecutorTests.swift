//
//  EditorCommandExecutorTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest

import Proton

class EditorCommandExecutorTests: XCTestCase {
    func testExecutesCommandOnEditor() {
        let context = EditorViewContext(name: "test_context")
        let commandExecutor = EditorCommandExecutor(context: context)
        let editor = EditorView(context: context)

        let selectedRange = NSRange(location: 3, length: 3)
        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = selectedRange

        guard let font = editor.selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
            XCTFail("Failed to get font information")
            return
        }

        XCTAssertFalse(font.isBold)

        commandExecutor.execute(BoldCommand())

        guard let updatedFont = editor.selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
            XCTFail("Failed to get font information")
            return
        }

        XCTAssertTrue(updatedFont.isBold)
    }

    func testExecuteAllCommandsByDefault() {
        let command1Expectation = functionExpectation("1")
        let command2Expectation = functionExpectation("2")

        let commandExecutor = EditorCommandExecutor()
        let editor = EditorView()

        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = editor.textEndRange

        let command1 = MockEditorCommand { e in
            XCTAssertEqual(e, editor)
            command1Expectation.fulfill()
        }

        let command2 = MockEditorCommand { e in
            XCTAssertEqual(e, editor)
            command2Expectation.fulfill()
        }

        commandExecutor.execute(command1)
        commandExecutor.execute(command2)
        waitForExpectations(timeout: 1.0)
    }

    func testExecutesOnlyRegisteredCommandsOnEditor() {
        let command1Expectation = functionExpectation("1")
        let command2Expectation = functionExpectation("2")
        command2Expectation.isInverted = true

        let commandExecutor = EditorCommandExecutor()
        let editor = EditorView()

        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = editor.textEndRange

        let command1 = MockEditorCommand { e in
            XCTAssertEqual(e, editor)
            command1Expectation.fulfill()
        }

        let command2 = MockEditorCommand { e in
            XCTAssertEqual(e, editor)
            command2Expectation.fulfill()
        }

        editor.registerCommand(command1)

        commandExecutor.execute(command1)
        commandExecutor.execute(command2)
        waitForExpectations(timeout: 1.0)
    }

    func testExecuteCommandsBasedOnContext() {
        let command1Expectation = functionExpectation("1")
        let command2Expectation = functionExpectation("2")
        command2Expectation.isInverted = true

        let context1 = EditorViewContext(name: "context_1")
        let context2 = EditorViewContext(name: "context_2")

        let commandExecutor1 = EditorCommandExecutor(context: context1)
        let commandExecutor2 = EditorCommandExecutor(context: context2)

        // Use the same context so that commandExecutor2 cannot run on editor2
        let editor1 = EditorView(context: context1)
        let editor2 = EditorView(context: context1)

        editor1.replaceCharacters(in: .zero, with: "This is some text")
        editor1.selectedRange = editor1.textEndRange

        let command1 = MockEditorCommand { e in
            XCTAssertEqual(e, editor1)
            command1Expectation.fulfill()
        }

        commandExecutor1.execute(command1)

        editor2.replaceCharacters(in: .zero, with: "This is some text")
        editor2.selectedRange = editor2.textEndRange

        let command2 = MockEditorCommand { e in
            XCTAssertEqual(e, editor2)
            command2Expectation.fulfill()
        }

        commandExecutor2.execute(command2)
        waitForExpectations(timeout: 1.0)
    }

    func testDoesNotExecuteCommandsIfRequiresCommandRegistrationAndNoCommandsRegistered() {
        let command1Expectation = functionExpectation("1")
        let command2Expectation = functionExpectation("2")

        command1Expectation.isInverted = true
        command2Expectation.isInverted = true

        let commandExecutor = EditorCommandExecutor()
        let editor = EditorView()

        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = editor.textEndRange

        let command1 = MockEditorCommand { e in
            XCTAssertEqual(e, editor)
            command1Expectation.fulfill()
        }

        let command2 = MockEditorCommand { e in
            XCTAssertEqual(e, editor)
            command2Expectation.fulfill()
        }

        editor.requiresSupportedCommandsRegistration = true

        commandExecutor.execute(command1)
        commandExecutor.execute(command2)
        waitForExpectations(timeout: 1.0)
    }
}
