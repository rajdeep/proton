//
//  TextBlockAttributeTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/5/20.
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
import UIKit

@testable import Proton

class TextBlockAttributeTests: XCTestCase {

    func testSetsFocusAfterForNonFocusableText() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = .zero
        let range = NSRange(location: 5, length: 0).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 8, length: 0))
    }

    func testSetsFocusBeforeForNonFocusableText() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text
        textView.selectedRange = NSRange(location: 9, length: 0)
        let range = NSRange(location: 6, length: 0).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 4, length: 0))
    }

    func testMaintainsNonTextBlockRangeSelectionWithShiftSelectionInReverse() {
        let textView = RichTextView(context: RichTextViewContext())

        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text
        textView.selectedRange = NSRange(location: 8, length: 2)
        let range = NSRange(location: 7, length: 3).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 4, length: 6))
    }

    func testMaintainsNonTextBlockRangeSelectionWithShiftSelectionInForward() {
        let textView = RichTextView(context: RichTextViewContext())

        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text
        textView.selectedRange = NSRange(location: 2, length: 1)
        let range = NSRange(location: 2, length: 4).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 2, length: 6))
    }

    func testRangeSelectionReverseForTextBlock() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string with attribute")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test
        textView.addAttributes([.textBlock: true], range: NSRange(location: 13, length: 6)) // string

        textView.selectedRange = NSRange(location: 12, length: 1) // space between test and string
        textView.selectedTextRange = NSRange(location: 11, length: 2).toTextRange(textInput: textView) // t (ending of test) and space
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 8, length: 5)) // "test " test and following space
    }

    func testRangeSelectionReverseForMultipleTextBlock() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string with attribute")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test
        textView.addAttributes([.textBlock: true], range: NSRange(location: 13, length: 6)) // string

        textView.selectedRange = NSRange(location: 12, length: 7) // " string" space followed by string
        textView.selectedTextRange = NSRange(location: 11, length: 8).toTextRange(textInput: textView) // "t string" t (ending of test), space and string
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 8, length: 11)) // "test string" test, space and string
    }

    func testRangeSelectionForwardForMultipleTextBlock() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string with attribute")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test
        textView.addAttributes([.textBlock: true], range: NSRange(location: 13, length: 6)) // string

        textView.selectedRange = NSRange(location: 12, length: 1) // space between test and string
        textView.selectedTextRange = NSRange(location: 12, length: 2).toTextRange(textInput: textView) //" s" space and (starting of string)
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 12, length: 7)) // " string" test and following space
    }

    func testSelectionWithTextBlocksWithNonTextBlockInMiddle() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string with attribute")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test
        textView.addAttributes([.textBlock: true], range: NSRange(location: 13, length: 6)) // string

        textView.selectedRange = NSRange(location: 8, length: 5) // " string" space followed by string
        textView.selectedTextRange = NSRange(location: 8, length: 6).toTextRange(textInput: textView) // "test s" test followed by space and s of string
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 8, length: 11)) // "test string" test, space and string
    }

    func testUnselectingSelectedMultipleTextBlockMovingLocationForward() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string with attribute")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test
        textView.addAttributes([.textBlock: true], range: NSRange(location: 13, length: 6)) // string

        textView.selectedRange = NSRange(location: 8, length: 11) // "test string" test, space and string
        textView.selectedTextRange = NSRange(location: 9, length: 10).toTextRange(textInput: textView) // "est string"
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 12, length: 7))
    }

    func testUnselectsSelectedTextBlockForward() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test

        textView.selectedRange = NSRange(location: 8, length: 4) // "test"
        textView.selectedTextRange = NSRange(location: 9, length: 3).toTextRange(textInput: textView) // "est"
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 12, length: 0))
    }

    func testUnselectsSelectedTextBlockReverse() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test

        textView.selectedRange = NSRange(location: 8, length: 4) // "test"
        textView.selectedTextRange = NSRange(location: 8, length: 3).toTextRange(textInput: textView) // "tes"
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 8, length: 0))
    }

    func testUnselectsTextSelectedWithTextBlockReverse() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "This is test string")
        textView.attributedText = text
        textView.addAttributes([.textBlock: true], range: NSRange(location: 8, length: 4)) // test

        textView.selectedRange = NSRange(location: 7, length: 5) // " test"
        textView.selectedTextRange = NSRange(location: 8, length: 4).toTextRange(textInput: textView) // "test"
        let range = textView.selectedRange

        XCTAssertEqual(range, NSRange(location: 8, length: 4))
    }

    func testSelectsTextBlockForward() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 4, length: 0)
        let range = NSRange(location: 4, length: 1).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 4, length: 4))
    }

    func testSelectsTextBlockReverse() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 8, length: 0)
        let range = NSRange(location: 7, length: 1).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 4, length: 4))
    }

    func testUnselectsTextBlockWithOtherTextReverse() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 3, length: 5)
        let range = NSRange(location: 3, length: 4).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 3, length: 1))
    }

    func testUnselectsTextWithBlockSelectedReverse() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 4, length: 5)
        let range = NSRange(location: 4, length: 4).toTextRange(textInput: textView)
        textView.selectedTextRange = range
        XCTAssertEqual(textView.selectedRange, NSRange(location: 4, length: 4))
    }

    func testDeleteBackwardsDefault() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 2, length: 0)
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "0234567890")
    }

    func testDeleteBackwardsOnTextBlock() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 8, length: 0)
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "0123890")
    }

    func testDeleteBackwardsOnTextBlockWithSameAttributeValues() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890", attributes: [.textBlock: true]))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 11, length: 0)
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "0123")
    }

    func testDeleteBackwardsOnTextBlockWithDifferentAttributeValues() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: UUID().uuidString]))
        text.append(NSAttributedString(string: "890", attributes: [.textBlock: UUID().uuidString]))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 11, length: 0)
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "01234567")
    }

    func testDeleteBackwardsOnTextBlockWithSelection() {
        let textView = RichTextView(context: RichTextViewContext())
        let text = NSMutableAttributedString(string: "0123")
        text.append(NSAttributedString(string: "4567", attributes: [.textBlock: true]))
        text.append(NSAttributedString(string: "890"))
        textView.attributedText = text

        textView.selectedRange = NSRange(location: 4, length: 6)
        textView.deleteBackward()
        XCTAssertEqual(textView.attributedText.string, "01230")
    }
}
