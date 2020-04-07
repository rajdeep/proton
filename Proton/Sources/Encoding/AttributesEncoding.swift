//
//  AttributesEncoding.swift
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
