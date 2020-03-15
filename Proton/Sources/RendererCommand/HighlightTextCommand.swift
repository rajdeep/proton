//
//  HighlightTextCommand.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString.Key {
    public static let isHighlighted = NSAttributedString.Key("IsHighlighted")
}

public class HighlightTextCommand: RendererCommand {
    public let color = UIColor(dynamicProvider: { traightCollection -> UIColor in
        switch traightCollection.userInterfaceStyle {
        case .dark:
            return UIColor.systemYellow.withAlphaComponent(0.2)
        default:
            return UIColor(red: 1.0, green: 0.98, blue: 0.80, alpha: 1.0)
        }
    })

    public init() {}

    public func execute(on renderer: RendererView) {
        guard renderer.selectedText.length > 0 else { return }
        let highlightedColor = renderer.selectedText.attribute(
            .backgroundColor, at: 0, effectiveRange: nil) as? UIColor

        guard highlightedColor != color else {
            renderer.removeAttributes(
                [.backgroundColor, .isHighlighted], at: renderer.selectedRange)
            return
        }

        renderer.addAttributes(
            [
                .backgroundColor: color,
                .isHighlighted: true,
            ], at: renderer.selectedRange)
    }
}
