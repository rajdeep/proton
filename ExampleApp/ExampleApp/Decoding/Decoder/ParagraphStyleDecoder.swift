//
//  ParagraphStyleDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

struct ParagraphStyleDecoder: AttributedStringAttributesDecoding {
    var name: String { "style" }

    func decode(_ json: JSON) -> Attributes {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment(rawValue: json["alignment"] as? Int ?? 0) ?? style.alignment
        style.firstLineHeadIndent = json["firstLineHeadIndent"] as? CGFloat ?? style.firstLineHeadIndent
        style.lineSpacing = json["linespacing"] as? CGFloat ?? style.lineSpacing
        style.paragraphSpacing = json["paragraphSpacing"] as? CGFloat ?? style.paragraphSpacing
        return [.paragraphStyle: style]
    }
}
