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

    func testReturnsAttributedStringForReverseRange() {
        let text = NSAttributedString(string: "This is a test string")
        let substring = text.reverseAttributedSubstring(from: NSRange(location: 9, length: 4))
        XCTAssertEqual(substring?.string, "is a")
    }
}
