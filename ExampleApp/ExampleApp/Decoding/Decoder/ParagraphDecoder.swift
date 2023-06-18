//
//  ParagraphDecoder.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 17/1/20.
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

struct ParagraphDecoder: EditorContentDecoding {
    func decode(mode: EditorContentMode, maxSize: CGSize, value: JSON, context: EditorDecodingContext?) throws -> NSAttributedString {
        let string = NSMutableAttributedString()
        var attr = Attributes()
        if let style = value["style"] as? JSON,
            let decoder = EditorContentJSONDecoder.attributeDecoders["style"] {
            attr = decoder.decode(style)

            string.append(try EditorContentJSONDecoder().decode(mode: mode, maxSize: maxSize, value: value, context: context))
        }
        string.append(NSAttributedString(string: "\n"))
        string.addAttributes(attr, range: string.fullRange)

        return string
    }
}
