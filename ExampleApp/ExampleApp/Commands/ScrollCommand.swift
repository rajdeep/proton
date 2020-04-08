//
//  ScrollCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
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
import UIKit

import Proton

class ScrollCommand: RendererCommand {
    var text = "Fusce"

    let name = CommandName("scrollCommand")

    func execute(on renderer: RendererView) {
        let location = renderer.selectedRange.location + renderer.selectedRange.length
        let range = NSRange(location: location, length: renderer.attributedText.length - location)
        for content in renderer.contents(in: range) {
            if case let .text(_, attributedString) = content.type,
                let range = attributedString.string.range(of: text, options: .caseInsensitive),
                let enclosingRange = content.enclosingRange {
                let contentRange = attributedString.string.makeNSRange(from: range)
                let scrollRange = NSRange(location: enclosingRange.location + contentRange.location + location, length: contentRange.length)
                renderer.selectedRange = scrollRange
                renderer.scrollRangeToVisible(scrollRange)
                break
            }
        }
    }
}
