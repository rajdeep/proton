//
//  FindTextCommand.swift
//  Proton
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
import Proton

class FindTextCommand: RendererCommand {
    var text = ""
    let name = CommandName("_findTextCommand")
    init(text: String) {
        self.text = text
    }

    func execute(on renderer: RendererView) {
        for content in renderer.contents() {
            if case let .text(_, attributedString) = content.type,
                let range = attributedString.string.range(of: text),
                let enclosingRange = content.enclosingRange {
                let contentRange = attributedString.string.makeNSRange(from: range)
                let scrollRange = NSRange(location: enclosingRange.location + contentRange.location, length: contentRange.length)
                renderer.addAttribute(.backgroundColor, value: PlatformColor.cyan, at: scrollRange)
                renderer.scrollRangeToVisible(scrollRange)
                break
            }
        }
    }
}
