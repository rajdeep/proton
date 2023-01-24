//
//  FontExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
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

public extension UIFont {

    var traits: UIFontDescriptor.SymbolicTraits {
        return fontDescriptor.symbolicTraits
    }

    var isBold: Bool {
        return traits.contains(.traitBold)
    }

    var isItalics: Bool {
        return traits.contains(.traitItalic)
    }

    var isMonoSpaced: Bool {
        return traits.contains(.traitMonoSpace) // iOS 14 mono font does not contain
            || fontName.contains("Monospaced") // eg. ".AppleSystemUIFontMonospaced-Regular"
    }

    var isAppleEmoji: Bool {
        return fontName == ".AppleColorEmojiUI" // inserted from iOS Emoji keyboard or macOS Character Viewer
            || fontName == "LastResort" // interesting font available since Mac OS 8.5 to render unsupported emoji
    }

    var textStyle: UIFont.TextStyle {
        guard let style = fontDescriptor.object(forKey: .textStyle) as? String else {
            return .body
        }
        return UIFont.TextStyle(rawValue: style)
    }

    var isNonDynamicTextStyle: Bool {
        return textStyle.rawValue == "CTFontRegularUsage"
    }

    func contains(trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        return traits.contains(trait)
    }

    func toggled(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let updatedFont: UIFont
        if self.contains(trait: trait) {
            updatedFont = removing(trait: trait)
        } else {
            updatedFont = adding(trait: trait)
        }

        return updatedFont
    }

    func adding(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        traits.formUnion(trait)
        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: pointSize)
    }

    func removing(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        var traits = self.traits
        traits.subtract(trait)
        guard let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }

        return UIFont(descriptor: updatedFontDescriptor, size: pointSize)
    }
}
