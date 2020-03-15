//
//  JSONTransformer.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

typealias JSON = [String: Any]

struct JSONEncoder: EditorContentEncoder {
    let textEncoders: [EditorContent.Name: AnyEditorTextEncoding<JSON>] = [
        EditorContent.Name.paragraph: AnyEditorTextEncoding(ParagraphEncoder()),
        .text: AnyEditorTextEncoding(TextEncoder()),
    ]

    let attachmentEncoders: [EditorContent.Name: AnyEditorContentAttachmentEncoding<JSON>] = [
        EditorContent.Name.panel: AnyEditorContentAttachmentEncoding(PanelEncoder()),
    ]
}
