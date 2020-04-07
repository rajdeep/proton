//
//  EditorContentEncoderTests.swift
//  Proton
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
import XCTest

import Proton

//class EditorContentEncoderTests: XCTestCase {
//    func testEncoding() {
//
//    }
//}
//
//struct ParagraphEncoder: EditorContentStringEncoding {
//    func encode(name: EditorContent.Name, string: NSAttributedString) -> JSON {
//        var paragraph = JSON()
//        paragraph.type = name.rawValue
//        if let style = string.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle {
//            paragraph[style.key] = style.value
//        }
//        paragraph.contents = contentsFrom(string)
//        return paragraph
//    }
//}
//
//struct PanelEncoding: EditorContentAttachmentEncoding {
//    func encode(name: EditorContent.Name, view: UIView) -> JSON {
//        guard let view = view as? PanelView else { return JSON() }
//
//        var json = JSON()
//        json.type = name.rawValue
//        json["style"] = "info"
//        let contents = view.editor.transformContents(using: JSONTransformer())
//        json.contents = contents
//        return json
//    }
//}
//
