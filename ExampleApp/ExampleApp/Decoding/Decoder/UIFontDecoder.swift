//
//  UIFontDecoder.swift
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

struct UIFontDecoder: AttributedStringAttributesDecoding {
    var name: String { return "font" }

    func decode(_ json: JSON) -> Attributes {
        guard
            let size = json["size"] as? CGFloat,
            let style = json["textStyle"] as? String,
            let family = json["family"] as? String else {
                return [.font: UIFont.preferredFont(forTextStyle: .body)]
        }

        let textStyle = UIFont.TextStyle(rawValue: style)
        var fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)

        // IMPORTANT - A bug in Apple's framework requires font family to be set before updating traits.
        // In absence of the following line, the font ends up defaulting to "Times New Roman" after
        // traits are applied using `fontDescriptor.withSymbolicTraits(traits)`
        fontDescriptor = fontDescriptor.withFamily(family)

        var traits = fontDescriptor.symbolicTraits
        if json["isBold"] as? Bool == true {
            traits.formUnion(.traitBold)
        }
        if json["isItalics"] as? Bool == true {
            traits.formUnion(.traitItalic)
        }
        if json["isMonospace"] as? Bool == true {
            traits.formUnion(.traitMonoSpace)
        }

        if let updatedFontDescriptor = fontDescriptor.withSymbolicTraits(traits) {
            fontDescriptor = updatedFontDescriptor
        }

        let font = UIFont(descriptor: fontDescriptor, size: size)
        return [.font: font]
    }
}
