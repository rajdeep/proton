//
//  FindTextCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

class FindTextCommand: RendererCommand {
    var text = ""

    init(text: String) {
        self.text = text
    }

    func execute(on renderer: RendererView) {
        for content in renderer.contents() {
            if case let .text(_, attributedString) = content.type,
                let range = attributedString.string.range(of: text),
                let enclosingRange = content.enclosingRange
            {
                let contentRange = attributedString.string.makeNSRange(from: range)
                let scrollRange = NSRange(
                    location: enclosingRange.location + contentRange.location,
                    length: contentRange.length)
                renderer.addAttribute(.backgroundColor, value: UIColor.cyan, at: scrollRange)
                renderer.scrollRangeToVisible(scrollRange)
                break
            }
        }
    }
}
