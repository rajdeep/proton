//
//  EditorContentEncoding.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

public protocol EditorContentEncoding {
    associatedtype EncodedType
    func encode(_ content: EditorContent) -> EncodedType!
}

public protocol EditorContentEncoder: EditorContentEncoding {
    associatedtype T
    var textEncoders: [EditorContent.Name: AnyEditorTextEncoding<T>] { get }

    var attachmentEncoders: [EditorContent.Name: AnyEditorContentAttachmentEncoding<T>] { get }

    func encode(_ content: EditorContent) -> T!
}

public extension EditorContentEncoder {
    func encode(_ content: EditorContent) -> T! {
        switch content.type {
        case .viewOnly:
            return nil
        case let .attachment(name, contentView, _):
            guard let encodable = attachmentEncoders[name] else { return nil }
            return encodable.encode(name: name, view: contentView)
        case let .text(name, attributedString):
            guard let encodable = textEncoders[name] else {  return nil }
            return encodable.encode(name: name, string: attributedString)
        }
    }
}
