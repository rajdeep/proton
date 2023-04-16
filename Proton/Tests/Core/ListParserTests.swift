//
//  ListParserTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 29/10/20.
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

import Proton

class ListParserTests: XCTestCase {

    func testParsesSingleLevelListFromString() {
        let line1 = "This is line 1. This is line 1. This is line 1. This is line 1."
        let line2 = "This is line 2."
        let line3 = "This is line 3. This is line 3. This is line 3. This is line 3."

        let text = """
        \(line1)
        \(line2)
        \(line3)
        """

        let paraStyle = NSMutableParagraphStyle.forListLevel(1)

        let attributedText = NSAttributedString(string: text, attributes: [.listItem: 1, .paragraphStyle: paraStyle])
        let list = ListParser.parse(attributedString: attributedText)
        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0].listItem.text.string, line1)
        XCTAssertEqual(list[1].listItem.text.string, line2)
        XCTAssertEqual(list[2].listItem.text.string, line3)


        XCTAssertEqual(list[0].listItem.level, 1)
        XCTAssertEqual(list[1].listItem.level, 1)
        XCTAssertEqual(list[2].listItem.level, 1)

        XCTAssertEqual(list[0].range, NSRange(location: 0, length: 63))
        XCTAssertEqual(list[1].range, NSRange(location: 64, length: 15))
        XCTAssertEqual(list[2].range, NSRange(location: 80, length: 63))
    }

    func testParsesSingleLevelListWithBlankLines() {
        let line1 = "This is line 1. This is line 1. This is line 1. This is line 1."
        let line2 = "This is line 2."

        let text = """
        \(line1)


        \(line2)
        """

        let paraStyle = NSMutableParagraphStyle.forListLevel(1)

        let attributedText = NSAttributedString(string: text, attributes: [.listItem: 1, .paragraphStyle: paraStyle])
        let list = ListParser.parse(attributedString: attributedText)
        XCTAssertEqual(list.count, 4)
        XCTAssertEqual(list[0].listItem.text.string, line1)
        XCTAssertEqual(list[1].listItem.text.string, "")
        XCTAssertEqual(list[2].listItem.text.string, "")
        XCTAssertEqual(list[3].listItem.text.string, line2)

        XCTAssertEqual(list[0].range, NSRange(location: 0, length: 63))
        XCTAssertEqual(list[1].range, NSRange(location: 64, length: 0))
        XCTAssertEqual(list[2].range, NSRange(location: 65, length: 0))
        XCTAssertEqual(list[3].range, NSRange(location: 66, length: 15))
    }

    func testParsesMultiLevelListFromString() {
        let paraStyle1 = NSMutableParagraphStyle.forListLevel(1)
        let paraStyle2 = NSMutableParagraphStyle.forListLevel(2)

        let text1 = "This is line 1. This is line 1. This is line 1. This is line 1.\n"
        let text1a = "Subitem 1 Subitem 1.\n"
        let text1b = "SubItem 2 SubItem 2.\n"
        let text2 = "This is line 2. This is line 2. This is line 2."

        let attributedString = NSMutableAttributedString(string: text1, attributes: [.paragraphStyle: paraStyle1])
        attributedString.append(NSAttributedString(string: text1a, attributes: [.paragraphStyle: paraStyle2]))
        attributedString.append(NSAttributedString(string: text1b, attributes: [.paragraphStyle: paraStyle2]))
        attributedString.append(NSAttributedString(string: text2, attributes: [.paragraphStyle: paraStyle1]))
        attributedString.addAttribute(.listItem, value: 1, range: attributedString.fullRange)

        let list = ListParser.parse(attributedString: attributedString)
        XCTAssertEqual(list.count, 4)

        XCTAssertEqual(list[0].listItem.level, 1)
        XCTAssertEqual(list[1].listItem.level, 2)
        XCTAssertEqual(list[2].listItem.level, 2)
        XCTAssertEqual(list[3].listItem.level, 1)

        XCTAssertEqual(list[0].listItem.text.string, String(text1.prefix(text1.count - 1)))
        XCTAssertEqual(list[1].listItem.text.string, String(text1a.prefix(text1a.count - 1)))
        XCTAssertEqual(list[2].listItem.text.string, String(text1b.prefix(text1b.count - 1)))
        XCTAssertEqual(list[3].listItem.text.string, text2)
    }

    func testParsesMultiLevelRepeatingList() {
        let levels = 3
        let paraStyles = (1...levels).map { NSMutableParagraphStyle.forListLevel($0) }

        let text = "Text\n"
        let attributedString = NSMutableAttributedString()
        for i in 0..<levels * 2 {
            let style = paraStyles[i % levels]
            attributedString.append(NSAttributedString(string: text, attributes: [.paragraphStyle: style]))
            attributedString.append(NSAttributedString(string: text, attributes: [.paragraphStyle: style]))
        }

        attributedString.addAttribute(.listItem, value: 1, range: attributedString.fullRange)
        let list = ListParser.parse(attributedString: attributedString)
        XCTAssertEqual(list.count, 12)
        for listItem in list {
            XCTAssertEqual(listItem.listItem.text.string, "Text")
        }

        XCTAssertEqual(list[0].listItem.level, 1)
        XCTAssertEqual(list[1].listItem.level, 1)
        XCTAssertEqual(list[2].listItem.level, 2)
        XCTAssertEqual(list[3].listItem.level, 2)
        XCTAssertEqual(list[4].listItem.level, 3)
        XCTAssertEqual(list[5].listItem.level, 3)
        XCTAssertEqual(list[6].listItem.level, 1)
        XCTAssertEqual(list[7].listItem.level, 1)
        XCTAssertEqual(list[8].listItem.level, 2)
        XCTAssertEqual(list[9].listItem.level, 2)
        XCTAssertEqual(list[10].listItem.level, 3)
        XCTAssertEqual(list[11].listItem.level, 3)
    }

    func testParsesSingleLevelListWithSkipNewLineFromString() {
        let line1 = "This is line 1. This is line 1. This is line 1. This is line 1."
        let line2 = "This is line 2."
        let line3 = "This is line 3. This is line 3. This is line 3. This is line 3."

        let paraStyle = NSMutableParagraphStyle.forListLevel(1)

        let attributedText = NSMutableAttributedString(string: line1)
        attributedText.append(NSAttributedString(string: "\n", attributes: [NSAttributedString.Key.skipNextListMarker: 1]))
        attributedText.append(NSAttributedString(string: line2))
        attributedText.append(NSAttributedString(string: "\n", attributes: [NSAttributedString.Key.blockContentType: EditorContent.Name.newline()]))
        attributedText.append(NSAttributedString(string: line3))
        attributedText.addAttributes([
            .paragraphStyle: paraStyle,
            .listItem: 1
        ], range: attributedText.fullRange)

        let list = ListParser.parse(attributedString: attributedText)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].listItem.text.string, "\(line1)\n\(line2)")
        XCTAssertEqual(list[1].listItem.text.string, line3)


        XCTAssertEqual(list[0].listItem.level, 1)
        XCTAssertEqual(list[1].listItem.level, 1)

        XCTAssertEqual(list[0].range, NSRange(location: 0, length: 79))
        XCTAssertEqual(list[1].range, NSRange(location: 80, length: 63))
    }

    func testParsesSingleLevelListToString() {
        var list = [ListItem]()
        let paraStyle = NSMutableParagraphStyle.forListLevel(1)
        list.append(ListItem(text: NSAttributedString(string: "Item 1"), level: 1, attributeValue: 1))
        list.append(ListItem(text: NSAttributedString(string: "Item 2"), level: 1, attributeValue: 1))
        list.append(ListItem(text: NSAttributedString(string: "Item 3"), level: 1, attributeValue: 1))

        let text = ListParser.parse(list: list, indent: 25)
        let expectedString = NSMutableAttributedString(string: "Item 1", attributes: [NSAttributedString.Key.paragraphStyle: paraStyle])
        expectedString.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle,
            NSAttributedString.Key.blockContentType: EditorContent.Name.newline()
        ]))
        expectedString.append(NSMutableAttributedString(string: "Item 2", attributes: [NSAttributedString.Key.paragraphStyle: paraStyle]))
        expectedString.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle,
            NSAttributedString.Key.blockContentType: EditorContent.Name.newline()
        ]))
        expectedString.append(NSMutableAttributedString(string: "Item 3", attributes: [NSAttributedString.Key.paragraphStyle: paraStyle]))
        expectedString.addAttribute(.listItem, value: 1, range: expectedString.fullRange)
        XCTAssertEqual(text, expectedString)
    }

    func testParsesMultiLevelListToString() {
        var list = [ListItem]()
        let paraStyle1 = NSMutableParagraphStyle.forListLevel(1)
        let paraStyle2 = NSMutableParagraphStyle.forListLevel(2)
        let paraStyle3 = NSMutableParagraphStyle.forListLevel(3)

        list.append(ListItem(text: NSAttributedString(string: "Item 1"), level: 1, attributeValue: 1))
        list.append(ListItem(text: NSAttributedString(string: "Item 2"), level: 2, attributeValue: 2))
        list.append(ListItem(text: NSAttributedString(string: "Item 3"), level: 3, attributeValue: 3))
        list.append(ListItem(text: NSAttributedString(string: "Item 4"), level: 1, attributeValue: 4))

        let text = ListParser.parse(list: list, indent: 25)
        let expectedString = NSMutableAttributedString(string: "Item 1", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle1,
            NSAttributedString.Key.listItem: 1
        ])
        expectedString.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedString.Key.blockContentType: EditorContent.Name.newline(),
            NSAttributedString.Key.paragraphStyle: paraStyle1,
            NSAttributedString.Key.listItem: 1
        ]))
        expectedString.append(NSMutableAttributedString(string: "Item 2", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle2,
            NSAttributedString.Key.listItem: 2
        ]))
        expectedString.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedString.Key.blockContentType: EditorContent.Name.newline(),
            NSAttributedString.Key.paragraphStyle: paraStyle2,
            NSAttributedString.Key.listItem: 2
        ]))
        expectedString.append(NSMutableAttributedString(string: "Item 3", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle3,
            NSAttributedString.Key.listItem: 3
        ]))
        expectedString.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedString.Key.blockContentType: EditorContent.Name.newline(),
            NSAttributedString.Key.paragraphStyle: paraStyle3,
            NSAttributedString.Key.listItem: 3
        ]))
        expectedString.append(NSMutableAttributedString(string: "Item 4", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle1,
            NSAttributedString.Key.listItem: 4
        ]))

        XCTAssertEqual(text, expectedString)
    }

    func testParsesListWithSkipListMarkerToString() {
        var list = [ListItem]()
        let paraStyle = NSMutableParagraphStyle.forListLevel(1)
        list.append(ListItem(text: NSAttributedString(string: "Item 1\nItem2"), level: 1, attributeValue: 1))
        list.append(ListItem(text: NSAttributedString(string: "Item 3"), level: 1, attributeValue: 1))

        let text = ListParser.parse(list: list, indent: 25)
        let expectedString = NSMutableAttributedString(string: "Item 1\nItem2", attributes: [NSAttributedString.Key.paragraphStyle: paraStyle])
        expectedString.addAttributes([.skipNextListMarker: 1, .blockContentType: EditorContent.Name.newline()], range: NSRange(location: 6, length: 1))
        expectedString.append(NSAttributedString(string: "\n", attributes: [
            NSAttributedString.Key.paragraphStyle: paraStyle,
            NSAttributedString.Key.blockContentType: EditorContent.Name.newline()
        ]))
        expectedString.append(NSMutableAttributedString(string: "Item 3", attributes: [NSAttributedString.Key.paragraphStyle: paraStyle]))
        expectedString.addAttribute(.listItem, value: 1, range: expectedString.fullRange)
        XCTAssertEqual(text, expectedString)
    }

    func testFullCircle() {
        var list = [ListItem]()

        let indent: CGFloat = 50

        list.append(ListItem(text: NSAttributedString(string: "Item 1\nItem2"), level: 1, attributeValue: 1))
        list.append(ListItem(text: NSAttributedString(string: "Item 3"), level: 1, attributeValue: 1))
        list.append(ListItem(text: NSAttributedString(string: "Item 31"), level: 2, attributeValue: 2))

        let text = ListParser.parse(list: list, indent: indent)
        let parsedList = ListParser.parse(attributedString: text, indent: 50)
        XCTAssertEqual(parsedList.count, list.count)

        for i in 0..<list.count {
            XCTAssertEqual(parsedList[i].listItem.text.string, list[i].text.string)
            XCTAssertEqual(parsedList[i].listItem.level, list[i].level)
            XCTAssertEqual(parsedList[i].listItem.attributeValue as? Int, list[i].attributeValue as? Int)
        }
    }

    func testAttributedStringWithoutList() {
        let text = NSAttributedString(string: "This is some string")
        let list = ListParser.parse(attributedString: text)
        XCTAssertEqual(list.count, 0)
    }

    func testParsesNonContinuousListString() {
        let paraStyle = NSMutableParagraphStyle.forListLevel(1)
        let line1 = NSAttributedString(string: "This is line 1. This is line 1. This is line 1. This is line 1.", attributes: [.listItem: 1, .paragraphStyle: paraStyle])
        let line2 = NSAttributedString(string: "This is line 2.")
        let line3 = NSAttributedString(string: "This is line 3. This is line 3. This is line 3.", attributes: [.listItem: 1, .paragraphStyle: paraStyle])

        let text = NSMutableAttributedString(attributedString: line1)
        text.append(NSAttributedString(string: "\n"))
        text.append(line2)
        text.append(NSAttributedString(string: "\n"))
        text.append( line3)

        let list = ListParser.parse(attributedString: text)
        XCTAssertEqual(list.count, 2)

        XCTAssertEqual(list[0].listItem.text.string, line1.string)
        XCTAssertEqual(list[1].listItem.text.string, line3.string)


        XCTAssertEqual(list[0].listItem.level, 1)
        XCTAssertEqual(list[1].listItem.level, 1)

        XCTAssertEqual(list[0].range, NSRange(location: 0, length: 63))
        XCTAssertEqual(list[1].range, NSRange(location: 80, length: 47))
    }
}
