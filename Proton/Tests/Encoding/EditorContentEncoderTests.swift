//
//  EditorContentEncoderTests.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import XCTest

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
