//
//  TextTransformer.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

import Proton

class TextTransformer: EditorContentEncoding {
    typealias EncodedType = String

    func encode(_ content: EditorContent) -> String! {
        let text: String

        switch content.type {
        case let .attachment(name, contentView, attachmentType):
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
