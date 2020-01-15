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

public protocol EditorContentTransforming {
    associatedtype TransformedType
    func transform(_ content: EditorContent) -> TransformedType!
}

public protocol EditorContentTransformer: EditorContentTransforming {
    associatedtype T
    var textTransformers: [EditorContent.Name: AnyEditorTextEncoding<T>] { get }

    var attachmentTransformers: [EditorContent.Name: AnyEditorContentAttachmentEncoding<T>] { get }

    func transform(_ content: EditorContent) -> T!
}

public extension EditorContentTransformer {
    func transform(_ content: EditorContent) -> T! {
        switch content.type {
        case .viewOnly:
            return nil
        case let .attachment(name, contentView, _):
            if let encodable = attachmentTransformers[name] {
                return encodable.encode(name: name, view: contentView)
            } else { return nil }
        case let .text(name, attributedString):
            if let encodable = textTransformers[name] {
                return encodable.encode(name: name, string: attributedString)
            } else { return nil }
        }
    }
}
