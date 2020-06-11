//
//  EditorListsSnapshotTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 31/5/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import XCTest
import SnapshotTesting

import Proton

class EditorListsSnapshotTests: XCTestCase {
    let listCommand = ListCommand()
    let listTextProcessor = ListTextProcessor()
    var recordMode = false
    let listFormattingProvider = MockListFormattingProvider()

    override func setUp() {
        super.setUp()
//        recordMode = true
        listCommand.attributeValue = true
    }

    func testInitiatesCreationOfList() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.listFormattingProvider = listFormattingProvider
        editor.selectedRange = .zero
        listCommand.execute(on: editor)
        viewController.render()

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testCreatesListFromSelectedText() {
        let text = """
        This is line 1. This is line 1. This is line 1. This is line 1.
        This is line 2.
        This is line 3. This is line 3. This is line 3. This is line 3.
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        viewController.render(size: CGSize(width: 300, height: 175))

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testIndentsAndOutdentsListWithoutSelectedRangeInBeginning() {
        let text = """
        This is line 1. This is line 1. This is line 1. This is line 1.
        This is line 2.
        This is line 3. This is line 3. This is line 3. This is line 3.
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let secondLine = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let rangeToSet = NSRange(location: secondLine.range.location, length: 0)
        editor.selectedRange = rangeToSet

        // Indent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Outdent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [.shift], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testIndentsAndOutdentsListWithoutSelectedRangeInEnd() {
        let text = """
        This is line 1. This is line 1. This is line 1. This is line 1.
        This is line 2.
        This is line 3. This is line 3. This is line 3. This is line 3.
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let secondLine = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let rangeToSet = NSRange(location: secondLine.range.endLocation, length: 0)
        editor.selectedRange = rangeToSet

        // Indent second line
            listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Outdent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [.shift], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testIndentsAndOutdentsListWithoutSelectedRangeInMiddle() {
        let text = """
           This is line 1. This is line 1. This is line 1. This is line 1.
           This is line 2.
           This is line 3. This is line 3. This is line 3. This is line 3.
           """

        let viewController = EditorTestViewController()
        let editor = viewController.editor

        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let secondLine = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let rangeToSet = NSRange(location: secondLine.range.location, length: 4)
        editor.selectedRange = rangeToSet

        // Indent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Outdent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [.shift], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testIndentsAndOutdentsListWithMultipleSelectedLines() {
        let text = """
        This is line 1. This is line 1. This is line 1. This is line 1.
        This is line 2.
        This is line 3. This is line 3. This is line 3. This is line 3.
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let secondLine = editor.contentLinesInRange(editor.attributedText.fullRange)[1]

        let secondAndThirdLineRange = NSRange(location: secondLine.range.location, length: editor.contentLength - secondLine.range.location)

        // Indent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: secondAndThirdLineRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // Outdent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [.shift], range: secondAndThirdLineRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testCreatesNewListItemOnReturnKey() {
        let text = "Test line."

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)
        editor.selectedRange = editor.textEndRange
        let attrs = editor.attributedText.attributes(at: editor.contentLength - 1, effectiveRange: nil)

        let paraStyle = attrs[.paragraphStyle] ?? NSParagraphStyle()
        editor.appendCharacters(NSAttributedString(string: "\n",
                                                   attributes: [
                                                    .paragraphStyle: paraStyle,
                                                    .listItem: 1]))
        editor.selectedRange =  NSRange(location: editor.textEndRange.location, length: 0)

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: NSRange(location: editor.textEndRange.location - 1, length: 1))
        listTextProcessor.didProcess(editor: editor)

        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testExitsNewListItemOnSecondReturnKey() {
        let text = "Test line."

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)
        editor.selectedRange = editor.textEndRange
        let attrs = editor.attributedText.attributes(at: editor.contentLength - 1, effectiveRange: nil)
        editor.appendCharacters(NSAttributedString(string: "\n", attributes: attrs))

        var editedRange = NSRange(location: editor.contentLength - 1, length: 1)
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: editedRange)
        listTextProcessor.didProcess(editor: editor) // invoke lifecycle event manually
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.appendCharacters(NSAttributedString(string: "\n", attributes: attrs))
        editedRange = NSRange(location: editor.contentLength - 1, length: 1)
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: editedRange)
        listTextProcessor.didProcess(editor: editor) // invoke lifecycle event manually
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testCreatesNewListItemOnSecondReturnKeyWhenInMiddleOfAList() {
        let text = """
               This is line 1.
               This is line 2.
               This is line 3.
               """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let secondLine = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let rangeToSet = NSRange(location: secondLine.range.location, length: 0)
        editor.selectedRange = rangeToSet

        // Indent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let location = secondLine.range.endLocation
        let attrs = editor.attributedText.attributes(at: location - 1, effectiveRange: nil)
        editor.replaceCharacters(in: NSRange(location: location, length: 0), with: NSAttributedString(string: "\n", attributes: attrs))

        var editedRange = NSRange(location: location, length: 1)
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: editedRange)
        listTextProcessor.didProcess(editor: editor) // invoke lifecycle event manually
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.replaceCharacters(in: NSRange(location: location, length: 0), with: NSAttributedString(string: "\n", attributes: attrs))
        editedRange = NSRange(location: location + 1, length: 1)
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: editedRange)
        listTextProcessor.didProcess(editor: editor) // invoke lifecycle event manually
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testAddsMultipleLevelOfLists() {
        let text = "Test line.\n"

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        for _ in 0..<9 {
            var range = NSRange(location: editor.contentLength - 1, length: 1)
            listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: range)
            range = editor.textEndRange//NSRange(location: editor.contentLength - 1, length: 1)
            listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: range)
            let attrs = editor.attributedText.attributes(at: editor.contentLength - 1, effectiveRange: nil)
            editor.appendCharacters(NSAttributedString(string: text, attributes: attrs))
        }

        viewController.render(size: CGSize(width: 400, height: 420))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testOutdentsNestedItems() {
        let text = """
        Line 1
        Line 2
        Line 2a

        Line 2a1

        Line 2a2
        Line 3
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let line2a = editor.contentLinesInRange(editor.attributedText.fullRange)[2]
        let line2a1 = editor.contentLinesInRange(editor.attributedText.fullRange)[4]
        let line2a2 = editor.contentLinesInRange(editor.attributedText.fullRange)[6]

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: NSRange(location: line2a.range.location, length: line2a2.range.endLocation - line2a.range.location))

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: line2a1.range)


        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [.shift], range: line2a.range)
        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testIndentsNestedItems() {
        let text = """
        Line 1
        Line 2
        Line 2a

        Line 2a1

        Line 2a2
        Line 3
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let line2 = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let line2a = editor.contentLinesInRange(editor.attributedText.fullRange)[2]
        let line2a2 = editor.contentLinesInRange(editor.attributedText.fullRange)[6]


        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: NSRange(location: line2a.range.location, length: line2a2.range.endLocation - line2a.range.location))

        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: line2.range)
        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testOutdentsToZerothLevel() {
        let text = """
        a
        b
        c
        d
        e
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let lines = editor.contentLinesInRange(editor.attributedText.fullRange)
        for i in 0..<lines.count {
            for _ in 0...i {
                listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: lines[i].range)
            }
        }

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let paraStyle = editor.attributedText.attribute(.paragraphStyle, at: editor.textEndRange.location - 1, effectiveRange: nil) ?? NSParagraphStyle()

        editor.appendCharacters(NSAttributedString(string: "\n",
                                                   attributes: [
                                                    .paragraphStyle: paraStyle,
                                                    .listItem: 1]))
        editor.selectedRange =  NSRange(location: editor.textEndRange.location, length: 0)

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: NSRange(location: editor.textEndRange.location - 1, length: 1))
        listTextProcessor.didProcess(editor: editor)

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        for _ in 0..<lines.count {
            editor.selectedRange =  NSRange(location: editor.textEndRange.location, length: 0)
            let paraStyle = editor.attributedText.attribute(.paragraphStyle, at: editor.textEndRange.location - 1, effectiveRange: nil) ?? NSParagraphStyle()
            editor.appendCharacters(NSAttributedString(string: "\n", attributes: [.paragraphStyle: paraStyle, .listItem: 1]))
            listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: NSRange(location: editor.textEndRange.location - 1, length: 1))
            listTextProcessor.didProcess(editor: editor)

            viewController.render(size: CGSize(width: 300, height: 400))
            assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
        }
    }

    func IGNORED_testDeletingBlankLineMovesToPreviousLine() {
        let text = "Hello world"

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        editor.registerProcessor(listTextProcessor)
        listCommand.execute(on: editor)

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: true)

        let paraStyle = editor.attributedText.attribute(.paragraphStyle, at: editor.textEndRange.location - 1, effectiveRange: nil) ?? NSParagraphStyle()

        editor.appendCharacters(NSAttributedString(string: "\n",
                                                   attributes: [
                                                    .paragraphStyle: paraStyle,
                                                    .listItem: 1]))
        editor.selectedRange =  NSRange(location: editor.textEndRange.location, length: 0)

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: NSRange(location: editor.textEndRange.location - 1, length: 1))
        listTextProcessor.didProcess(editor: editor)

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: true)

        editor.appendCharacters(NSAttributedString(string: "\n",
                                                   attributes: [
                                                    .paragraphStyle: paraStyle,
                                                    .listItem: 1]))
        editor.selectedRange =  NSRange(location: editor.textEndRange.location, length: 0)

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .enter, modifierFlags: [], range: NSRange(location: editor.textEndRange.location - 1, length: 1))
        listTextProcessor.didProcess(editor: editor)

        print("Before: \(editor.contentLength)  \(editor.attributedText)")
        editor.deleteBackward()
        print("After: \(editor.contentLength)  \(editor.attributedText)")

        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .backspace, modifierFlags: [], range: NSRange(location: editor.textEndRange.location - 1, length: 1))

        viewController.render(size: CGSize(width: 300, height: 400))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testQueriesDelegateForListLineMarker() {
        let funcExpectation = functionExpectation()
        funcExpectation.expectedFulfillmentCount = 2

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider()
        let attributeValue = "ListItemAttribute"

        var expectedValues = [
            (index: 0, level: 1, prevLevel: 0, attributeValue: attributeValue),
            (index: 0, level: 2, prevLevel: 1, attributeValue: attributeValue),
        ]

        listFormattingProvider.onListMarkerForItem = { _, index, level, prevLevel, attrVal in
            XCTAssertEqual(index, expectedValues[0].index)
            XCTAssertEqual(level, expectedValues[0].level)
            XCTAssertEqual(prevLevel, expectedValues[0].prevLevel)
            XCTAssertEqual(attrVal as? String, expectedValues[0].attributeValue)
            funcExpectation.fulfill()
            expectedValues.remove(at: 0)
        }

        editor.listFormattingProvider = listFormattingProvider

        let text = "This is line 1.\nThis is line 2."

        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor, attributeValue: attributeValue)

        let secondLine = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let rangeToSet = NSRange(location: secondLine.range.location, length: 0)
        editor.selectedRange = rangeToSet

        // Indent second line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: editor.selectedRange)
        viewController.render(size: CGSize(width: 300, height: 175))

        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
        waitForExpectations(timeout: 1.0)
    }

    func testRemoveListAttributeFromRange() {
        let text = """
        Line 1
        Line 2
        Line 2a
        Line 2a1
        Line 2a2
        Line 3
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let line2 = editor.contentLinesInRange(editor.attributedText.fullRange)[1]
        let line2a = editor.contentLinesInRange(editor.attributedText.fullRange)[2]
        let line2a2 = editor.contentLinesInRange(editor.attributedText.fullRange)[4]


        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: NSRange(location: line2a.range.location, length: line2a2.range.endLocation - line2a.range.location))
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: line2.range)

        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.selectedRange = NSRange(location: 0, length: line2a.range.endLocation)
        listCommand.execute(on: editor, attributeValue: nil)

        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        // For some reason, a re-render is required in tests
        viewController.render(size: CGSize(width: 300, height: 225))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersListWithDifferentAttributeValues() {
        let text = """
        This is line 1.
        This is line 2.
        This is line 3.
        This is line 4.
        """

        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider
        editor.attributedText = NSAttributedString(string: text)
        editor.selectedRange = editor.attributedText.fullRange
        listCommand.execute(on: editor)

        let thirdLine = editor.contentLinesInRange(editor.attributedText.fullRange)[2]

        let thirdAndFourthLineRange = NSRange(location: thirdLine.range.location, length: editor.contentLength - thirdLine.range.location)

        // Indent third & fourth line
        listTextProcessor.handleKeyWithModifiers(editor: editor, key: .tab, modifierFlags: [], range: thirdAndFourthLineRange)
        editor.addAttribute(.listItem, value: 2, at: thirdAndFourthLineRange)
        
        viewController.render(size: CGSize(width: 300, height: 175))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testRendersListInAttributedString() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider

        let indent: CGFloat = 25
        let paraStyle1 = NSMutableParagraphStyle()
        paraStyle1.firstLineHeadIndent = indent * 1
        paraStyle1.headIndent = indent * 1

        let paraStyle2 = NSMutableParagraphStyle()
        paraStyle2.firstLineHeadIndent = indent * 2
        paraStyle2.headIndent = indent * 2

        let paraStyle3 = NSMutableParagraphStyle()
        paraStyle3.firstLineHeadIndent = indent * 3
        paraStyle3.headIndent = indent * 3

        editor.appendCharacters(NSAttributedString(string: "Ordered 1\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "Unordered 2\n", attributes: [.listItem: 2, .paragraphStyle: paraStyle2]))
        editor.appendCharacters(NSAttributedString(string: "Unordered 2\n", attributes: [.listItem: 2, .paragraphStyle: paraStyle2]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 3\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle3]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 3\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle3]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 1-2\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "Unordered 2\n", attributes: [.listItem: 2, .paragraphStyle: paraStyle2]))
        editor.appendCharacters(NSAttributedString(string: "Unordered 2\n", attributes: [.listItem: 2, .paragraphStyle: paraStyle2]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 3\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle3]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 3\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle3]))
        editor.appendCharacters(NSAttributedString(string: "Not in list\n", attributes: [.paragraphStyle: NSParagraphStyle()]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 1\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "Unordered 2\n", attributes: [.listItem: 2, .paragraphStyle: paraStyle2]))
        editor.appendCharacters(NSAttributedString(string: "Unordered 2\n", attributes: [.listItem: 2, .paragraphStyle: paraStyle2]))
        editor.appendCharacters(NSAttributedString(string: "Ordered 1", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))

        viewController.render(size: CGSize(width: 300, height: 375))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testContinuesNumberingWhenTwoListsAreCombined() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider

        let indent: CGFloat = 25
        let paraStyle1 = NSMutableParagraphStyle()
        paraStyle1.firstLineHeadIndent = indent * 1
        paraStyle1.headIndent = indent * 1

        let paraStyle2 = NSMutableParagraphStyle()
        paraStyle2.firstLineHeadIndent = indent * 2
        paraStyle2.headIndent = indent * 2

        let paraStyle3 = NSMutableParagraphStyle()
        paraStyle3.firstLineHeadIndent = indent * 3
        paraStyle3.headIndent = indent * 3

        editor.appendCharacters(NSAttributedString(string: "Item 1\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "Item 2\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "Item 3", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "\nNot in list", attributes: [.paragraphStyle: NSParagraphStyle()]))
        editor.appendCharacters(NSAttributedString(string: "\nItem 4\n", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))
        editor.appendCharacters(NSAttributedString(string: "Item 5", attributes: [.listItem: 1, .paragraphStyle: paraStyle1]))

        viewController.render(size: CGSize(width: 300, height: 180))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        let lines = editor.contentLinesInRange(editor.attributedText.fullRange)
        let notInListLine = lines[3]

        editor.selectedRange = notInListLine.range
        listCommand.execute(on: editor, attributeValue: 1)

        viewController.render(size: CGSize(width: 300, height: 180))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }

    func testAppliesAndRemovesListStyleToEntireLineOnPartialSelection() {
        let viewController = EditorTestViewController()
        let editor = viewController.editor
        let listFormattingProvider = MockListFormattingProvider(sequenceGenerators: [NumericSequenceGenerator(), DiamondBulletSequenceGenerator()])
        editor.listFormattingProvider = listFormattingProvider

        let indent: CGFloat = 25
        let paraStyle1 = NSMutableParagraphStyle()
        paraStyle1.firstLineHeadIndent = indent * 1
        paraStyle1.headIndent = indent * 1

        let paraStyle2 = NSMutableParagraphStyle()
        paraStyle2.firstLineHeadIndent = indent * 2
        paraStyle2.headIndent = indent * 2

        let paraStyle3 = NSMutableParagraphStyle()
        paraStyle3.firstLineHeadIndent = indent * 3
        paraStyle3.headIndent = indent * 3

        editor.appendCharacters(NSAttributedString(string: "Item 1\n"))
        editor.appendCharacters(NSAttributedString(string: "Item 2\n"))
        editor.appendCharacters(NSAttributedString(string: "Item 3"))

        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        editor.selectedRange = NSRange(location: 3, length: editor.contentLength - 3)
        listCommand.execute(on: editor, attributeValue: 1)

        viewController.render(size: CGSize(width: 300, height: 180))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        listCommand.execute(on: editor, attributeValue: nil)

        viewController.render(size: CGSize(width: 300, height: 180))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)
    }
}
