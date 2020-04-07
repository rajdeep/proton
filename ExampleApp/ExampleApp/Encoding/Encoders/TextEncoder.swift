//
//  TextEncoder.swift
//  ExampleApp
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
import UIKit

import Proton

enum InlineValueType {
    case single(value: Any?)
    case json(value: JSON?)
}

protocol InlineEncoding {
    var key: String { get }
    var value: InlineValueType { get }
}

struct TextEncoder: EditorTextEncoding {
    func encode(name: EditorContent.Name, string: NSAttributedString) -> JSON {
        var text = JSON()
        string.enumerateAttributes(in: string.fullRange, options: .longestEffectiveRangeNotRequired) { (attributes, range, _) in
            let substring = string.attributedSubstring(from: range)
            text.type = name.rawValue
            text["text"] = substring.string
            for attr in attributes {
                if let encoding = attr.value as? InlineEncoding {
                    switch encoding.value {
                    case let .json(value):
                        text[encoding.key] = value
                    case .single(let value):
                        text[encoding.key] = value
                    }
                }
            }
        }
        return text
    }
}
