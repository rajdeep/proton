//
//  RendererCommandExecutorTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import XCTest

class RendererCommandExecutorTests: XCTestCase {
    func testExecutesCommandOnRenderer() {
        let context = RendererViewContext(name: "test_context")
        let commandExecutor = RendererCommandExecutor(context: context)
        let renderer = RendererView(context: context)

        let selectedRange = NSRange(location: 3, length: 3)
        renderer.attributedText = NSAttributedString(string: "This is some text")
        renderer.selectedRange = selectedRange

        let color = renderer.selectedText.attribute(.backgroundColor, at: 0, effectiveRange: nil)
            as? UIColor
        XCTAssertNil(color)

        let command = HighlightTextCommand()
        commandExecutor.execute(command)

        guard
            let highlightColor = renderer.selectedText.attribute(
                .backgroundColor, at: 0, effectiveRange: nil) as? UIColor
        else {
            XCTFail("Failed to get background color information")
            return
        }

        XCTAssertEqual(highlightColor, command.color)
    }
}
