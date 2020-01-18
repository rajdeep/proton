//
//  UIFontDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

struct UIFontDecoder: AttributedStringAttributesDecoding {
    var name: String { return "font" }

    func decode(_ json: JSON) -> Attributes {
        guard let name = json["name"] as? String,
            let size = json["size"] as? CGFloat,
            let family = json["family"] as? String else {
                return [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        }

        var fontDescriptor = UIFontDescriptor(name: name, size: size)
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
        return [NSAttributedString.Key.font: font]
    }
}
