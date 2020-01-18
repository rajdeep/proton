//
//  AttributesEncoding.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public protocol EditorTextEncoding {
    associatedtype EncodedType
    func encode(name: EditorContent.Name, string: NSAttributedString) -> EncodedType
}

public struct AnyEditorTextEncoding<T>: EditorTextEncoding {
    public typealias EncodedType = T
    let encoding: (_ name: EditorContent.Name, _ string: NSAttributedString) -> T

    public init<E: EditorTextEncoding>(_ encoder: E) where E.EncodedType == T {
        encoding = encoder.encode
    }

    public func encode(name: EditorContent.Name, string: NSAttributedString) -> T {
        return encoding(name, string)
    }
}

public protocol AttachmentEncoding {
    associatedtype EncodedType
    func encode(name: EditorContent.Name, view: UIView) -> EncodedType
}

public struct AnyEditorContentAttachmentEncoding<T>: AttachmentEncoding {
    public typealias EncodedType = T
    let encoding: (_ name: EditorContent.Name, _ view: UIView) -> T

    public init<E: AttachmentEncoding>(_ encoder: E) where E.EncodedType == T {
        encoding = encoder.encode
    }

    public func encode(name: EditorContent.Name, view: UIView) -> T {
        return encoding(name, view)
    }
}
