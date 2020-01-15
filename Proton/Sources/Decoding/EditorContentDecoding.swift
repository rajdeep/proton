//
//  EditorContentDecoding.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

public enum EditorContentMode {
    case editor
    case renderer
}

public protocol EditorContentDecoding {
    associatedtype TypeToDecode
    func decode(mode: EditorContentMode, maxSize: CGSize, value: TypeToDecode) -> NSAttributedString
}

public struct AnyEditorContentDecoding<T>: EditorContentDecoding {
    let decoding: (EditorContentMode, CGSize, T) -> NSAttributedString

    public init<D:EditorContentDecoding>(_ decoder: D) where D.TypeToDecode == T {
        decoding = decoder.decode
    }

    public func decode(mode: EditorContentMode, maxSize: CGSize, value: T) -> NSAttributedString {
        return decoding(mode, maxSize, value)
    }
}
