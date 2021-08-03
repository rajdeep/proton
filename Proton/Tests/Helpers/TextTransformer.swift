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

struct TextEncoder: EditorContentEncoder {
    let textEncoders: [EditorContent.Name: AnyEditorTextEncoding<String>] = [
        EditorContent.Name.paragraph: AnyEditorTextEncoding(ParagraphTextEncoder()),
        .text: AnyEditorTextEncoding(TextTransformer()),
        .newline: AnyEditorTextEncoding(NewlineTextEncoder()),
    ]

    let attachmentEncoders: [EditorContent.Name: AnyEditorContentAttachmentEncoding<String>] = [
        EditorContent.Name("textField") : AnyEditorContentAttachmentEncoding(TextTransformer()),
    ]
}

struct ParagraphTextEncoder: EditorTextEncoding {
    func encode(name: EditorContent.Name, string: NSAttributedString) -> String {
        return contentsFrom(string).joined(separator: "\n")
    }
}

struct NewlineTextEncoder: EditorTextEncoding {
    func encode(name: EditorContent.Name, string: NSAttributedString) -> String {
        return "Name: `\(EditorContent.Name.newline.rawValue)` Text: `\n`"
    }
}


extension ParagraphTextEncoder {
    func contentsFrom(_ string: NSAttributedString) -> [String] {
        var contents = [String]()
        string.enumerateInlineContents().forEach { content in
            switch content.type {
            case .viewOnly:
                break
            case let .text(name, attributedString):
                let text = TextTransformer().encode(name: name, string: attributedString)
                contents.append(text)
            case let .attachment(name, _, contentView, _):
                let text = TextTransformer().encode(name: name, view: contentView)
                contents.append(text)
            }
        }
        return contents
    }
}

struct TextTransformer: EditorTextEncoding, AttachmentEncoding {
    func encode(name: EditorContent.Name, string: NSAttributedString) -> String {
        return "Name: `\(name.rawValue)` Text: `\(string.string)`"
    }

    func encode(name: EditorContent.Name, view: NativeView) -> String {
        let contentViewType = String(describing: type(of: view))
        return  "Name: `\(name.rawValue)` ContentView: `\(contentViewType)`"
        //Type: `\(attachmentType)`
    }
}
