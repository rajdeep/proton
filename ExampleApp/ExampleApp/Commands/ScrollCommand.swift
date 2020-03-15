//
//  ScrollCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

class ScrollCommand: RendererCommand {
    var text = "Fusce"

    func execute(on renderer: RendererView) {
        let location = renderer.selectedRange.location + renderer.selectedRange.length
        let range = NSRange(location: location, length: renderer.attributedText.length - location)
        for content in renderer.contents(in: range) {
            if case let .text(_, attributedString) = content.type,
                let range = attributedString.string.range(of: text, options: .caseInsensitive),
                let enclosingRange = content.enclosingRange
            {
                let contentRange = attributedString.string.makeNSRange(from: range)
                let scrollRange = NSRange(
                    location: enclosingRange.location + contentRange.location + location,
                    length: contentRange.length)
                renderer.selectedRange = scrollRange
                renderer.scrollRangeToVisible(scrollRange)
                break
            }
        }
    }
}
