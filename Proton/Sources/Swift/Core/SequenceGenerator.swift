//
//  SequenceGenerator.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 27/5/20.
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

/// Represents a Sequence generator that can return a value based on given index.
/// Besides other possible uses, this is used in Lists for generation of bullets/numbering.
public protocol SequenceGenerator {
    /// Returns a value representing the given index.
    /// - Parameter index: Index for which the value is being fetched.
    func value(at index: Int) -> ListLineMarker
}

/// Simple numeric sequence generator.
public struct NumericSequenceGenerator: SequenceGenerator {
    public init() { }
    public func value(at index: Int) -> ListLineMarker {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let text = "\(index + 1)."
        return .string(NSAttributedString(string: text, attributes: [.font: font]))
    }
}

/// Simple bullet sequence generator that returns a diamond symbol.
public struct DiamondBulletSequenceGenerator: SequenceGenerator {
    public init() { }
    public func value(at index: Int) -> ListLineMarker {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let text = "◈"
        return .string(NSAttributedString(string: text, attributes: [.font: font]))
    }
}

/// Simple bullet sequence generator that returns a square symbol.
public struct SquareBulletSequenceGenerator: SequenceGenerator {
    public init() { }
    public func value(at index: Int) -> ListLineMarker {
        if let image = UIImage(systemName: "square.fill") {
            return .image(image, size: CGSize(width: 5, height: 5))
        } else {
            let font = UIFont.preferredFont(forTextStyle: .body)
            let text = "▣"
            return .string(NSAttributedString(string: text, attributes: [.font: font]))
        }
    }
}
