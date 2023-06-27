//
//  AsyncTextResolverSnapshotTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 4/6/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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
import SnapshotTesting

@testable import Proton

class AsyncTextResolverSnapshotTests: SnapshotTestCase {
    func testIgnoresTextAsyncAttributeUntilInvoked() {
        let expectation = functionExpectation()
        let viewController = EditorTestViewController(height: 130)
        let editor = viewController.editor
        editor.asyncTextResolvers = [DummyResolver()]
        let text = NSMutableAttributedString(string: "This is some text with link ")
        text.append(NSAttributedString(string: "http://google.com", attributes: [.asyncTextResolver: "dummy"]))
        text.append(NSAttributedString(string: " and another link "))
        text.append(NSAttributedString(string: "http://abc.com", attributes: [.asyncTextResolver: "dummy"]))
        text.append(NSAttributedString(string: " followed by some more text"))
        editor.setNeedsAsyncTextResolution()
        editor.attributedText = text

        viewController.render(size: CGSize(width: 300, height: 170))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            viewController.render(size: CGSize(width: 300, height: 170))
            assertSnapshot(matching: viewController.view, as: Snapshotting.image, record: self.recordMode)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testResolvesAsyncAttributeInOrder() {
        let expectation = functionExpectation()
        let viewController = EditorTestViewController(height: 130)
        let editor = viewController.editor
        editor.asyncTextResolvers = [DummyResolver()]
        let text = NSMutableAttributedString(string: "This is some text with link ")
        text.append(NSAttributedString(string: "http://abc.com", attributes: [.asyncTextResolver: "dummy"]))
        text.append(NSAttributedString(string: " and another link "))
        text.append(NSAttributedString(string: "http://google.com", attributes: [.asyncTextResolver: "dummy"]))
        text.append(NSAttributedString(string: " followed by some more text"))
        editor.setNeedsAsyncTextResolution()
        editor.attributedText = text

        viewController.render(size: CGSize(width: 300, height: 170))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            viewController.render(size: CGSize(width: 300, height: 170))
            assertSnapshot(matching: viewController.view, as: Snapshotting.image, record: self.recordMode)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testDiscardsAsyncAttributeInOrder() {
        let expectation = functionExpectation()
        let viewController = EditorTestViewController(height: 130)
        let editor = viewController.editor
        editor.asyncTextResolvers = [DummyResolver()]
        let text = NSMutableAttributedString(string: "This is some text with link ")
        text.append(NSAttributedString(string: "http://abc.com", attributes: [.asyncTextResolver: "dummy"]))
        text.append(NSAttributedString(string: " and another link "))
        text.append(NSAttributedString(string: "http://google.com", attributes: [.asyncTextResolver: "dummy"]))
        text.append(NSAttributedString(string: " followed by some more text"))
        editor.setNeedsAsyncTextResolution()
        editor.attributedText = text
        // break the link
        editor.replaceCharacters(in: NSRange(location: 65, length: 0), with: NSAttributedString(string: " "))

        viewController.render(size: CGSize(width: 300, height: 170))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            viewController.render(size: CGSize(width: 300, height: 170))
            assertSnapshot(matching: viewController.view, as: Snapshotting.image, record: self.recordMode)

            let attributeRange = viewController.editor.attributedText.rangeOf(attribute: .asyncTextResolver, startingLocation: 0)
            XCTAssertNil(attributeRange)

            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }


}

class DummyResolver: AsyncTextResolving {
    var name: String { "dummy" }

    func resolve(using editor: EditorView, range: NSRange, string: NSAttributedString, completion: @escaping (AsyncTextResolvingResult) -> Void) {
        let mutableString: NSMutableAttributedString
        if string.string == "http://google.com" {
            mutableString = NSMutableAttributedString(string: "Google")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                mutableString.addAttribute(.foregroundColor, value: UIColor.red, range: mutableString.fullRange)
                mutableString.removeAttribute(.asyncTextResolver, range: mutableString.fullRange)
                completion(.apply(mutableString, range: range))
            }
        } else if string.string == "http://abc.com" {
            mutableString = NSMutableAttributedString(string: "Australian Broadcasting Corporation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                mutableString.addAttribute(.foregroundColor, value: UIColor.blue, range: mutableString.fullRange)
                mutableString.removeAttribute(.asyncTextResolver, range: mutableString.fullRange)
                completion(.apply(mutableString, range: range))
            }
        } else {
            mutableString = NSMutableAttributedString(attributedString: string)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion(.discard)
            }
        }
    }
}
