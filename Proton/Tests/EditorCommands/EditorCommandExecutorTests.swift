//
//  EditorCommandExecutorTests.swift
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

@testable import Proton

class EditorCommandExecutorTests: XCTestCase {
    func testExecutesCommandOnEditor() {
        let context = EditorViewContext(name: "test_context")
        let commandExecutor = EditorCommandExecutor(context: context)
        let editor = EditorView(context: context)

        let selectedRange = NSRange(location: 3, length: 3)
        context.didBeginEditing(editor)
        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = selectedRange

        guard let font = editor.selectedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else {
            XCTFail("Failed to get font information")
            return
        }

        XCTAssertFalse(font.isBold)

        let colorCommand = MockEditorCommand { editor in
            editor.addAttributes([.foregroundColor: UIColor.red], at: editor.selectedRange)
        }

        commandExecutor.execute(colorCommand)

        guard let updatedColor = editor.selectedText.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor else {
            XCTFail("Failed to get font information")
            return
        }

        XCTAssertEqual(updatedColor, UIColor.red)
    }

    func testExecuteAllCommandsByDefault() {
        let command1Expectation = functionExpectation("1")
        let command2Expectation = functionExpectation("2")

        let commandExecutor = EditorCommandExecutor()
        let editor = EditorView()
        editor.editorViewContext.didBeginEditing(editor)
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
        editor.editorViewContext.didBeginEditing(editor)
        editor.replaceCharacters(in: .zero, with: "This is some text")
        editor.selectedRange = editor.textEndRange

        let command1 = MockEditorCommand(name: "command1") { e in
            XCTAssertEqual(e, editor)
            command1Expectation.fulfill()
        }

        let command2 = MockEditorCommand(name: "command2") { e in
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

        context1.didBeginEditing(editor1)
        editor1.replaceCharacters(in: .zero, with: "This is some text")
        editor1.selectedRange = editor1.textEndRange

        let command1 = MockEditorCommand { e in
            XCTAssertEqual(e, editor1)
            command1Expectation.fulfill()
        }

        commandExecutor1.execute(command1)
        context2.didBeginEditing(editor2)
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

        editor.registeredCommands = []

        commandExecutor.execute(command1)
        commandExecutor.execute(command2)
        waitForExpectations(timeout: 1.0)
    }
}

extension EditorViewContext {
    func didBeginEditing(_ editor: EditorView) {
        richTextViewContext.textViewDidBeginEditing(editor.richTextView)
    }
}
