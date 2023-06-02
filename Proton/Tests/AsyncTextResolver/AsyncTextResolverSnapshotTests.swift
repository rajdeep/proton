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
        expectation.expectedFulfillmentCount = 2
        let viewController = EditorTestViewController(height: 80)
        let editor = viewController.editor
        editor.asyncTextResolvers = [DummyResolver()]
        editor.attributedText = NSAttributedString(string: "This is some text")
        editor.addAttribute(.asyncTextResolver, value: "dummy", at: NSRange(location: 8, length: 4))

        viewController.render(size: CGSize(width: 300, height: 150))
        assertSnapshot(matching: viewController.view, as: .image, record: recordMode)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewController.render(size: CGSize(width: 300, height: 150))
            assertSnapshot(matching: viewController.view, as: Snapshotting.image, record: self.recordMode)
            expectation.fulfill()
            // Invoke async text resolution
            editor.resolveAsyncTextIfNeeded()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewController.render(size: CGSize(width: 300, height: 150))
            assertSnapshot(matching: viewController.view, as: Snapshotting.image, record: self.recordMode)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }
}

class DummyResolver: AsyncTextResolving {
    var name: String { "dummy" }

    func resolve(using editor: EditorView, range: NSRange, string: NSAttributedString, completion: @escaping (AsyncTextResolvingResult) -> Void) {
        let mutableString = NSMutableAttributedString(attributedString: string)

        mutableString.addAttribute(.foregroundColor, value: UIColor.red, range: mutableString.fullRange)
        mutableString.removeAttribute(.asyncTextResolver, range: mutableString.fullRange)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if editor.attributedText.attributedSubstring(from: range).string == string.string {
                completion(.apply(mutableString, range: range))
            } else {
                completion(.discard)
            }
        }
    }
}
