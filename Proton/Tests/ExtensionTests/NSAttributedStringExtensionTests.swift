//
//  NSAttributedStringExtensionTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 4/3/20.
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

class NSAttributedStringExtensionTests: XCTestCase {
    func testGetsFullRange() {
        let text = NSAttributedString(string: "This is a test string")
        let range = text.fullRange
        XCTAssertEqual(range, NSRange(location: 0, length: text.length))
    }

    func testGetsSubstring() {
        let text = NSAttributedString(string: "This is a test string")
        let substring = text.substring(from: NSRange(location: 5, length: 2))
        XCTAssertEqual(substring, "is")
    }

    func testGetRangeForAttachment() {
        let string = "This is a test string"
        let text = NSMutableAttributedString(string: string)
        let attachment = Attachment(AutogrowingTextField(), size: .matchContent)
        text.append(attachment.string)
        text.append(NSAttributedString(string: " some more text"))
        let range = text.rangeFor(attachment: attachment)
        XCTAssertEqual(range, NSRange(location: string.count, length: 1))
    }

    func testGetsRangesForNewLinesCharacter() {
        let text = NSAttributedString(string: "This is a test string\nAnd second line\n")
        let ranges = text.rangesOf(characterSet: .newlines)
        XCTAssertEqual(ranges.count, 2)
        XCTAssertEqual(ranges[0], NSRange(location: 21, length: 1))
        XCTAssertEqual(ranges[1], NSRange(location: 37, length: 1))
    }

    func testGetsRangesForCharacterSet() {
        let text = NSAttributedString(string: "0123456789")
        let ranges = text.rangesOf(characterSet: CharacterSet(charactersIn: "17"))
        XCTAssertEqual(ranges.count, 2)
        XCTAssertEqual(ranges[0], NSRange(location: 1, length: 1))
        XCTAssertEqual(ranges[1], NSRange(location: 7, length: 1))
    }

    func testGetsRangeForCharacterSet() {
        let text = NSAttributedString(string: "0123456789")
        let range = text.rangeOfCharacter(from: CharacterSet(charactersIn: "5"))
        XCTAssertEqual(range, NSRange(location: 5, length: 1))
    }

    func testReturnsNilForInvalidReverseRange() {
        let text = NSAttributedString()
        let substring = text.reverseAttributedSubstring(from: NSRange(location: 2, length: 2))
        XCTAssertNil(substring)
    }

    func testReturnsNilForInvalidNegativeReverseRange() {
        let text = NSAttributedString(string: "test")
        let substring = text.reverseAttributedSubstring(from: NSRange(location: -2, length: 2))
        XCTAssertNil(substring)
    }

    func testReturnsReverseRange() {
        let text = NSAttributedString(string: "test")
        let range = text.reverseRange(of: "tE", startingLocation: 3)
        XCTAssertEqual(range, NSRange(location: 0, length: 2))
    }

    func testReturnsNilReverseRangeOnOutOfBoundsLocation() {
        let text = NSAttributedString(string: "test")
        let range = text.reverseRange(of: "tE", startingLocation: 10)
        XCTAssertNil(range)
    }

    func testReturnsNilReverseRangeOnNegativeLocation() {
        let text = NSAttributedString(string: "test")
        let range = text.reverseRange(of: "tE", startingLocation: -1)
        XCTAssertNil(range)
    }

    func testReturnsAttributedStringForReverseRange() {
        let text = NSAttributedString(string: "This is a test string")
        let substring = text.reverseAttributedSubstring(from: NSRange(location: 9, length: 4))
        XCTAssertEqual(substring?.string, "is a")
    }

    func testGetsRangeOfAttributeStartingAtLocation() {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let range = attributedString.rangeOf(attribute: testAttribute, startingLocation: 2)
        XCTAssertEqual(range, attributeRange)
    }

    func testGetsRangeOfAttributeStartingAtLocationTraversingReverse() {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let range = attributedString.rangeOf(attribute: testAttribute, startingLocation: 17, reverseLookup: true)
        XCTAssertEqual(range, attributeRange)
    }

    func testStartingRangeOfAttributeInEmptyString() {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSAttributedString()
        let range = text.rangeOf(attribute: testAttribute, startingLocation: 5)
        XCTAssertNil(range)
    }

    func testGetsAttributeStartingAtLocation() {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let attributeValue: Bool? = attributedString.attributeValue(for: testAttribute, at: 12)
        XCTAssertEqual(attributeValue, true)
    }

    func testMissingAttributeAtLocation() {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSAttributedString(string: "This is a test string")
        let attributeValue: Bool? = text.attributeValue(for: testAttribute, at: 12)
        XCTAssertNil(attributeValue)
    }

    func testAttributeAtLocationInEmptyString() {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSAttributedString()
        let attributeValue: Bool? = text.attributeValue(for: testAttribute, at: 12)
        XCTAssertNil(attributeValue)
    }

    func testRangeOfAttributeAtLocationAtStart()  {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let range = attributedString.rangeOf(attribute: testAttribute, at: 10)
        XCTAssertEqual(range, attributeRange)
    }

    func testRangeOfAttributeAtLocationInMiddle()  {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let range = attributedString.rangeOf(attribute: testAttribute, at: 12)
        XCTAssertEqual(range, attributeRange)
    }

    func testRangeOfAttributeAtLocationAtEnd()  {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let range = attributedString.rangeOf(attribute: testAttribute, at: 13)
        XCTAssertEqual(range, attributeRange)
    }

    func testRangeOfAttributeAtLocationOutsideRange()  {
        let testAttribute = NSAttributedString.Key("testAttr")
        let text = NSMutableAttributedString(string: "This is a test string")
        let attributeRange = NSRange(location: 10, length: 4)
        text.addAttribute(testAttribute, value: true, range: attributeRange)
        let attributedString = NSAttributedString(attributedString: text)
        let range = attributedString.rangeOf(attribute: testAttribute, at: 0)
        XCTAssertNil(range)
    }

    func testGetsReverseRangeOfText() {
        let text = NSMutableAttributedString(string: "This is a test string")
        let range = text.reverseRange(of: "is", startingLocation: text.length - 1)
        XCTAssertEqual(range, NSRange(location: 5, length: 2))
    }

    func testFailsReverseRangeOfTextCaseSensitive() {
        let text = NSMutableAttributedString(string: "This is a test string")
        let range = text.reverseRange(of: "Is", startingLocation: text.length - 1, isCaseInsensitive: false)
        XCTAssertNil(range)
    }

    func testGetsReverseRangeOfTextCaseSensitive() {
        let text = NSMutableAttributedString(string: "This is a test string")
        let range = text.reverseRange(of: "Is", startingLocation: text.length - 1)
        XCTAssertEqual(range, NSRange(location: 5, length: 2))
    }

    func testDoesNotFindReverseRangeOfText() {
        let text = NSMutableAttributedString(string: "This is a test string")
        let range = text.reverseRange(of: "isx", startingLocation: text.length - 1)
        XCTAssertNil(range)
    }

    func testEnumeratesIgnoringValue() {
        let text = NSMutableAttributedString(string: "This is a test string", attributes: [.inlineContentType: "a"])
        text.append(NSAttributedString(string: " Some more text", attributes: [.inlineContentType: "b"]))
        text.append(NSAttributedString(string: " And more text", attributes: [.inlineContentType: "c"]))
        text.append(NSAttributedString(string: "Not with attribute", attributes: [:]))
        text.append(NSAttributedString(string: "Again with attribute", attributes: [.inlineContentType: "c"]))

        let expected = [
            ("This is a test string Some more text And more text", true),
            ("Not with attribute", false),
            ("Again with attribute", true)
        ]
        var counter = 0
        text.enumerateContinuousRangesByAttribute(.inlineContentType) { isPresent, range in
            XCTAssertEqual(expected[counter].0, text.substring(from: range))
            XCTAssertEqual(expected[counter].1, isPresent)
            counter += 1
        }
        XCTAssertEqual(counter, 3)
    }
}
