//
//  ParagraphDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 17/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

struct ParagraphDecoder: EditorContentDecoding {
    func decode(mode: EditorContentMode, maxSize: CGSize, value: JSON) -> NSAttributedString {
        let string = NSMutableAttributedString()
        var attr = Attributes()
        if let style = value["style"] as? JSON,
            let decoder = EditorContentJSONDecoder.attributeDecoders["style"]
        {
            attr = decoder.decode(style)

            string.append(
                EditorContentJSONDecoder().decode(mode: mode, maxSize: maxSize, value: value))
        }
        string.append(NSAttributedString(string: "\n"))
        string.addAttributes(attr, range: string.fullRange)

        return string
    }
}
