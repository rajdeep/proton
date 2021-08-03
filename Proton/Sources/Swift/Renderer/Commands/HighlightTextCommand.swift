//
//  HighlightTextCommand.swift
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
#if os(iOS)
#else
import AppKit
#endif

public extension NSAttributedString.Key {
    static let isHighlighted = NSAttributedString.Key("_IsHighlighted")
}

@available(iOS 13.0, *)
/// Renderer command that toggles highlights in the selected range in Renderer.
public class HighlightTextCommand: RendererCommand {

    public let name = CommandName("_highlightCommand")
    
    lazy var defaultColor: PlatformColor = {
        let lightYellow = PlatformColor.systemYellow.withAlphaComponent(0.2)
        let darkYellow = PlatformColor(red: 1.0, green: 0.98, blue: 0.80, alpha: 1.0)
        #if os(iOS)
        return PlatformColor(dynamicProvider: { traitCollection -> PlatformColor in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return lightYellow
            default:
                return darkYellow
            }
        })
        #else
        return PlatformColor(name: nil) { appearance in
            if appearance.isDarkMode {
                return darkYellow
                
            } else {
                return lightYellow
            }
        }
        #endif
    }()
    
    public var color: PlatformColor?

    public init() { }

    /// Executes the command on Renderer in the selected range
    /// - Parameter renderer: Renderer to execute the command on.
    public func execute(on renderer: RendererView) {
        guard renderer.selectedText.length > 0 else { return }

        let color = self.color ?? defaultColor
        let highlightedColor = renderer.selectedText.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? PlatformColor

        guard highlightedColor != color else {
            renderer.removeAttributes([.backgroundColor, .isHighlighted], at: renderer.selectedRange)
            return
        }

        renderer.addAttributes([
            .backgroundColor: color,
            .isHighlighted: true,
        ], at: renderer.selectedRange)
    }
}
