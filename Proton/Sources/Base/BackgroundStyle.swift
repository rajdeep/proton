//
//  BackgroundStyle.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/5/20.
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

/// Shadow style for background attribute
public struct ShadowStyle {

    /// Color of the shadow
    public let color: UIColor

    /// Shadow offset
    public let offset: CGSize

    /// Shadow blur
    public let blur: CGFloat

    public init(color: UIColor, offset: CGSize, blur: CGFloat) {
        self.color = color
        self.offset = offset
        self.blur = blur
    }
}

/// Additional style for background color attribute. Adding `BackgroundStyle` attribute in addition to
/// `backgroundColor` attribute will apply shadow and rounded corners as specified.
/// - Note:
/// This attribute had no effect in absence of `backgroundColor` attribute.
public struct BackgroundStyle {

    /// Corner radius of the background
    public let cornerRadius: CGFloat

    /// Optional shadow style for the background
    public let shadow: ShadowStyle?

    public init(cornerRadius: CGFloat = 0, shadow: ShadowStyle? = nil) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
}
