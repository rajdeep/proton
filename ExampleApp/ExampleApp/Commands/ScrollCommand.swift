//
//  ScrollCommand.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class ScrollCommand: RendererCommand {
    var text = "est" //"Fusce"

    func execute(on renderer: RendererView) {
        for content in renderer.contents() {
            if case let .text(_, attributedString) = content.type,
                let range = attributedString.string.range(of: text) {
                let scrollRange = attributedString.string.makeNSRange(from: range)
                renderer.addAttribute(.backgroundColor, value: UIColor.cyan, at: scrollRange)
                renderer.scrollRangeToVisible(scrollRange)
                break
            }
        }
    }
}
