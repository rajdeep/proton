//
//  JSONTransformer.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

typealias JSON = [String: Any]

struct JSONTransformer: EditorContentTransformer {

    let textTransformers: [EditorContent.Name: AnyEditorTextEncoding<JSON>] = [
        EditorContent.Name.paragraph: AnyEditorTextEncoding(ParagraphEncoder()),
        .text: AnyEditorTextEncoding(TextEncoder())
    ]

    let attachmentTransformers: [EditorContent.Name: AnyEditorContentAttachmentEncoding<JSON>] = [
        EditorContent.Name.panel: AnyEditorContentAttachmentEncoding(PanelEncoder()),
    ]
}
