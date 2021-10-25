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

/// Shadow style for `backgroundStyle` attribute
public class ShadowStyle {

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

/// Border style for `backgroundStyle` attribute
public class BorderStyle {

    /// Color of border
    public let color: UIColor

    /// Width of the border
    public let lineWidth: CGFloat

    public init(lineWidth: CGFloat, color: UIColor) {
        self.lineWidth = lineWidth
        self.color = color
    }
}

/// Rounding style for  `backgroundStyle` attribute
public enum RoundedCornerStyle {
    /// Rounding based on an absolute value for corner radii
    case absolute(value: CGFloat)
    /// Rounding based on relative percent value of the content height. For e.g. 50% would provide a capsule appearance
    /// for shorter content.
    case relative(percent: CGFloat)
}

/// Defines the height used for the background for the text
public enum BackgroundHeightMode {
    /// Background matches the height of the text. If the text range contains varied font size,
    /// the height of tallest font is used for entire continuous range of text. The height is not affected
    /// by large/small text in the same line with no background or that not in continuous range.
    case matchText
    /// Background matches the height of tallest font/character in the laid out line fragment, irrespective of the fact if
    /// the tallest character has background style applied to it or not. This is the default value for height calculations.
    case matchLine
}

/// Style for background color attribute. Adding `backgroundStyle` attribute will add border, background and shadow
/// as per the styles specified.
/// - Important:
/// This attribute is separate from `backgroundColor` attribute. Applying `backgroundColor` takes precedence over backgroundStyle`
/// i.e. the background color shows over color of `backgroundStyle` and will not show rounded corners.
/// - Note:
/// Ideally `backgroundStyle` may be used instead of `backgroundColor` as it can mimic standard background color as well as
/// border, shadow and rounded corners.
public class BackgroundStyle {

    /// Background color
    public let color: UIColor

    /// Rounding style for the background
    public let roundedCornerStyle: RoundedCornerStyle

    /// Optional border style for the background
    public let border: BorderStyle?

    /// Optional shadow style for the background
    public let shadow: ShadowStyle?

    /// Determines if the background has squared off joins at the point of wrapping of content.
    /// When set to `true`, the background will be squared off at inner/wrapping edges
    /// in case the background wraps across multiple lines. Defaults to `false`.
    /// - Note: This may be desirable to use in cases of short length content that is ideal to be shown as a single continued entity.
    /// When combined with `RoundedCornerStyle.relative` with a value of `50%`, it can help mimic appearance of a broken capsule
    /// when content wraps to next line.
    public let hasSquaredOffJoins: Bool

    /// Defines if the background should be drawn based on height of text range with style, or that of the height of line fragment containing
    /// styled text.
    public let heightMode: BackgroundHeightMode

    /// Insets for drawn background. Defaults to `.zero`
    public let insets: UIEdgeInsets

    public init(color: UIColor,
                roundedCornerStyle: RoundedCornerStyle = .absolute(value: 0),
                border: BorderStyle? = nil,
                shadow: ShadowStyle? = nil,
                hasSquaredOffJoins: Bool = false,
                heightMode: BackgroundHeightMode = .matchLine,
                insets: UIEdgeInsets = .zero) {
        self.color = color
        self.roundedCornerStyle = roundedCornerStyle
        self.border = border
        self.shadow = shadow
        self.hasSquaredOffJoins = hasSquaredOffJoins
        self.heightMode = heightMode
        self.insets = insets
    }
}
