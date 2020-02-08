//
//  RendererViewTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 14/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import XCTest

@testable import Proton

class RendererViewTests: XCTestCase {
    func testInvokesDelegateOnSelectionChanged() {
        let testExpectation = functionExpectation()

        let delegate = MockRendererViewDelegate()
        let renderer = RendererView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 50)))
        renderer.attributedText = NSAttributedString(string: "This is a test string")
        renderer.delegate = delegate
        renderer.enableSelectionHandles = false
        let selectedRange = NSRange(location: 4, length: 4)
        delegate.onDidChangeSelection = { _, range in
            XCTAssertEqual(range, selectedRange)
            testExpectation.fulfill()
        }

        renderer.selectedRange = selectedRange
        waitForExpectations(timeout: 1.0)
    }

    func testSelectsAttachmentInSelectedRange() {
        let testExpectation = functionExpectation()

        let delegate = MockRendererViewDelegate()
        let renderer = RendererView()
        renderer.enableSelectionHandles = false
        let attachment = Attachment(PanelView(), size: .fullWidth)
        let attrString = NSMutableAttributedString(string: "This is a test string")
        attrString.append(attachment.string)
        renderer.attributedText = attrString

        renderer.delegate = delegate
        XCTAssertFalse(attachment.isSelected)
        delegate.onDidChangeSelection = { _, _ in
            XCTAssertTrue(attachment.isSelected)
            testExpectation.fulfill()
        }

        renderer.selectedRange = renderer.attributedText.fullRange
        waitForExpectations(timeout: 1.0)
    }

    func testGetsCharacterRangeFromLocation() {
        let testExpectation = functionExpectation()

        let delegate = MockRendererViewDelegate()
        let renderer = RendererView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 50)))
        let attachment = Attachment(PanelView(), size: .fullWidth)
        let attrString = NSMutableAttributedString(string: "This is a test string")
        attrString.append(attachment.string)
        renderer.attributedText = attrString

        renderer.delegate = delegate

        delegate.onDidTap = { _, _, charRange in
            XCTAssertEqual(charRange, NSRange(location: 4, length: 1))
            testExpectation.fulfill()
        }

        renderer.didTap(at: CGPoint(x: 40, y: 15))
        waitForExpectations(timeout: 1.0)
    }
}
