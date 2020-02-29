//
//  AttributesDecoding.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 18/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

protocol AttributedStringAttributesDecoding {
    associatedtype TypeToDecode
    var name: String { get }
    func decode(_ value: TypeToDecode) -> Attributes
}

struct AnyAttributedStringAttributeDecoding<EncodedType>: AttributedStringAttributesDecoding {
    let name: String
    let decoding: (EncodedType) -> Attributes

    init<D: AttributedStringAttributesDecoding>(_ decoder: D) where EncodedType == D.TypeToDecode {
        self.name = decoder.name
        self.decoding = decoder.decode
    }

    func decode(_ value: EncodedType) -> Attributes {
        return decoding(value)
    }
}
