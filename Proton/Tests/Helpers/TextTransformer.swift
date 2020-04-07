//
//  TextTransformer.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
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

import Proton

class TextTransformer: EditorContentEncoding {
    typealias EncodedType = String

    func encode(_ content: EditorContent) -> String! {
        let text: String

        switch content.type {
        case let .attachment(name, _, contentView, attachmentType):
            let contentViewType = String(describing: type(of: contentView))
            text = "Name: `\(name.rawValue)` ContentView: `\(contentViewType)` Type: `\(attachmentType)`"
        case let .text(name, attributedString):
            text = "Name: `\(name.rawValue)` Text: `\(attributedString.string)`"
        case .viewOnly:
            text = "ViewOnly"
        }
        return text
    }
}
