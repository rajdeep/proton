//
//  ParagraphStyleDecoder.swift
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

struct ParagraphStyleDecoder: AttributedStringAttributesDecoding {
    var name: String { return "style" }

    func decode(_ json: JSON) -> Attributes {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment(rawValue: json["alignment"] as? Int ?? 0) ?? style.alignment
        style.firstLineHeadIndent = json["firstLineHeadIndent"] as? CGFloat ?? style.firstLineHeadIndent
        style.lineSpacing = json["linespacing"] as? CGFloat ?? style.lineSpacing
        style.paragraphSpacing = json["paragraphSpacing"] as? CGFloat ?? style.paragraphSpacing
        return [.paragraphStyle: style]
    }
}
