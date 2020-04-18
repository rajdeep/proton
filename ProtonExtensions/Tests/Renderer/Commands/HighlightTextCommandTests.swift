//
//  HighlightTextCommandTests.swift
//  ProtonExtensionsTests
//
//  Created by Rajdeep Kwatra on 18/4/20.
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
@testable import ProtonExtensions

class HighlightTextCommandTests: XCTestCase {
    func testHighlightsText() {
        let renderer = RendererView()
        let rangeToHighlight = NSRange(location: 0, length: 4)
        renderer.attributedText = NSAttributedString(string: "This is some text")
        renderer.selectedRange = rangeToHighlight

        let highlightBefore = renderer.attributedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNil(highlightBefore)

        let command = HighlightTextCommand()
        command.execute(on: renderer)
        var effectiveRange = NSRange()

        let highlightAfter = renderer.attributedText.attribute(.backgroundColor, at: 0, effectiveRange: &effectiveRange) as? UIColor
        XCTAssertEqual(highlightAfter, command.defaultColor)
        XCTAssertEqual(effectiveRange, rangeToHighlight)
    }

    func testRemovesHighlightsFromTextForSameColor() {
        let renderer = RendererView()
        let rangeToHighlight = NSRange(location: 0, length: 4)
        renderer.attributedText = NSAttributedString(string: "This is some text")
        renderer.selectedRange = rangeToHighlight

        let command = HighlightTextCommand()
        command.execute(on: renderer) // applies

        command.execute(on: renderer) // removes

        let highlightColor = renderer.attributedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? UIColor
        XCTAssertNil(highlightColor)
    }

    func testUpdatesHighlightsForDifferentColor() {
        let renderer = RendererView()
        let rangeToHighlight = NSRange(location: 0, length: 4)
        renderer.attributedText = NSAttributedString(string: "This is some text")
        renderer.selectedRange = rangeToHighlight

        let command = HighlightTextCommand()
        command.execute(on: renderer) // applies default
        command.color = .red

        command.execute(on: renderer) // applies red

        var effectiveRange = NSRange()
        let highlightColor = renderer.attributedText.attribute(.backgroundColor, at: 0, effectiveRange: &effectiveRange) as? UIColor
        XCTAssertEqual(highlightColor, .red)
        XCTAssertEqual(effectiveRange, rangeToHighlight)
    }
}
