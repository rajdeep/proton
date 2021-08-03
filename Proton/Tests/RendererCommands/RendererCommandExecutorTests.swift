//
//  RendererCommandExecutorTests.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
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

class RendererCommandExecutorTests: XCTestCase {
    func testExecutesCommandOnRenderer() {
        let context = RendererViewContext(name: "test_context")
        let commandExecutor = RendererCommandExecutor(context: context)
        let renderer = RendererView(context: context)

        let selectedRange = NSRange(location: 3, length: 3)
        renderer.attributedText = NSAttributedString(string: "This is some text")
        renderer.selectedRange = selectedRange

        let color = renderer.selectedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? PlatformColor
        XCTAssertNil(color)

        let command = MockRendererCommand { renderer in
            renderer.addAttributes([.foregroundColor: PlatformColor.red], at: renderer.selectedRange)
        }
        commandExecutor.execute(command)

        guard let newColor = renderer.selectedText.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? PlatformColor else {
            XCTFail("Failed to get background color information")
            return
        }

        XCTAssertEqual(newColor, PlatformColor.red)
    }
}
