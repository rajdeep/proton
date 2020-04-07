//
//  TextStorageTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
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

class TextStorageTests: XCTestCase {
    func testAddsDefaultTextFormatting() {
        let textStorage = TextStorage()
        let string = "This is a test string"
        textStorage.replaceCharacters(in: .zero, with: NSAttributedString(string: string))
        var effectiveRange = NSRange.zero
        let attributes = textStorage.attributes(at: 0, effectiveRange: &effectiveRange)

        XCTAssertEqual(textStorage.string, string)
        XCTAssertNotNil(attributes[.paragraphStyle])
        XCTAssertNotNil(attributes[.font])
        XCTAssertEqual(effectiveRange, textStorage.fullRange)
    }

    func testAddTextFormattingUsingProvider() throws{
        let textStorage = TextStorage()
        let font = try XCTUnwrap(UIFont(name: "Arial", size: 30))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.firstLineHeadIndent = 6

        let textFormattingProvider = MockDefaultTextFormattingProvider(font: font, paragraphStyle: paragraphStyle)

        let string = "This is a test string"
        textStorage.defaultTextFormattingProvider = textFormattingProvider
        textStorage.replaceCharacters(in: .zero, with: NSAttributedString(string: string))

        var effectiveRange = NSRange.zero
        let attributes = textStorage.attributes(at: 0, effectiveRange: &effectiveRange)

        XCTAssertEqual(attributes[.paragraphStyle] as? NSParagraphStyle, paragraphStyle)
        XCTAssertEqual(attributes[.font] as? UIFont, font)
        XCTAssertEqual(effectiveRange, textStorage.fullRange)
    }

    func testAddsAttribute() {
        let textStorage = TextStorage()
        let key = NSAttributedString.Key("custom_attr")
        let customAttribute = [key: true]
        let range = NSRange(location: 0, length: 4)
        textStorage.replaceCharacters(in: .zero, with: NSAttributedString(string: "test string"))

        textStorage.addAttributes(customAttribute, range: range)

        var effectiveRange = NSRange.zero
        let attributes = textStorage.attributes(at: 0, effectiveRange: &effectiveRange)

        XCTAssertEqual(attributes[key] as? Bool, true)
        XCTAssertEqual(effectiveRange, range)
    }

    func testRemoveAttributes() {
        let textStorage = TextStorage()
        let testString = "test string"
        let key = NSAttributedString.Key("custom_attr")
        let customAttribute = [key: true]
        let range = NSRange(location: 0, length: 4)
        textStorage.replaceCharacters(in: .zero, with: NSAttributedString(string: testString))
        textStorage.addAttributes(customAttribute, range: textStorage.fullRange)

        textStorage.removeAttribute(key, range: range)

        var effectiveRange = NSRange.zero
        let attributes = textStorage.attributes(at: 0, effectiveRange: &effectiveRange)

        XCTAssertNil(attributes[key])
        XCTAssertEqual(effectiveRange, range)

        let keyAttributes = textStorage.attributes(at: range.length, effectiveRange: &effectiveRange)

        XCTAssertEqual(keyAttributes[key] as? Bool, true)
        XCTAssertEqual(effectiveRange, NSRange(location: range.length, length: testString.count - range.length))
    }

    func testFixesMissingDefaultAttributesWhenRemoved() {
        let textStorage = TextStorage()
        let testString = NSAttributedString(string: "test string")
        textStorage.replaceCharacters(in: .zero, with: testString)

        let defaultAttributes = textStorage.attributes(at: 0, effectiveRange: nil)
        XCTAssertTrue(defaultAttributes.contains { $0.key == .font })
        XCTAssertTrue(defaultAttributes.contains { $0.key == .foregroundColor })
        XCTAssertTrue(defaultAttributes.contains { $0.key == .paragraphStyle })

        textStorage.removeAttributes([.font, .foregroundColor, .paragraphStyle], range: textStorage.fullRange)

        let fixedAttributes = textStorage.attributes(at: 0, effectiveRange: nil)
        XCTAssertTrue(fixedAttributes.contains { $0.key == .font })
        XCTAssertTrue(fixedAttributes.contains { $0.key == .foregroundColor })
        XCTAssertTrue(fixedAttributes.contains { $0.key == .paragraphStyle })
    }
}
