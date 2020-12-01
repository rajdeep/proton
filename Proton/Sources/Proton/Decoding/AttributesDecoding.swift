//
//  AttributesDecoding.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 17/1/20.
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

/// An object capable of decoding attributes for use in `NSAttributedString`
public protocol AttributesDecoding {
    associatedtype TypeToDecode
    var name: String { get }
    func decode(_ value: TypeToDecode) -> Attributes
}

/// A type-erased implementation of `AttributesDecoding`
public struct AnyAttributeDecoding<EncodedType>: AttributesDecoding {
    public let name: String
    let decoding: (EncodedType) -> Attributes

    public init<D: AttributesDecoding>(_ decoder: D) where EncodedType == D.TypeToDecode {
        self.name = decoder.name
        self.decoding = decoder.decode
    }

    public func decode(_ value: EncodedType) -> Attributes {
        return decoding(value)
    }
}
