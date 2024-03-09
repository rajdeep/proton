//
//  GridConfiguration.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
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

/// Defines configuration for Columns
class GridColumnDimension {
    var isCollapsed: Bool
    var width: GridColumnWidth
    let collapsedWidth: CGFloat

    /// Instantiates dimension for Grid Columns
    /// - Parameters:
    ///   - width: Default column width
    ///   - isCollapsed: Determines if column is collapsed
    ///   - collapsedWidth: Default width for collapsed column.
    init(width: GridColumnWidth, isCollapsed: Bool = false, collapsedWidth: CGFloat) {
        self.isCollapsed = isCollapsed
        self.width = width
        self.collapsedWidth = collapsedWidth
    }

    func value(basedOn total: CGFloat, viewportWidth: CGFloat) -> CGFloat {
        guard !isCollapsed else { return collapsedWidth }
        return width.value(basedOn: total, viewportWidth: viewportWidth)
    }
}

/// Defines how Grid Column width should be calculated
public enum GridColumnWidth {
    /// Defines a fixed with for column
    /// - Parameter : `CGFloat` value for width.
    case fixed(CGFloat)
    /// Defines a fixed with for column
    /// - Parameters :
    ///     -  : `CGFloat` value for percentage of available width.
    ///     - min: Closure providing minimum value for column. If computed fractional value is less than min, min is used.
    ///     - max: Closure providing maximum value for column. If computed fractional value is more than max, max is used.
    /// - Note: Percentage is calculated based on total available width for GridView, typically, width of containing `EditorView`
    case fractional(CGFloat, min: (() -> CGFloat)? = nil, max: (() -> CGFloat)? = nil)

    /// Defines width based on available viewport.
    /// - Parameter padding: Padding for adjusting width with respect to viewport. Positive values decreases column width from viewport width and negative
    /// increases column width by padding over viewport width,
    case viewport(padding: CGFloat)

    func value(basedOn total: CGFloat, viewportWidth: CGFloat) -> CGFloat {
        switch self {
        case let .fixed(value):
            return value
        case let .fractional(value, min, max):
            let fractionalValue = value * total
            if let min = min?(),
               fractionalValue < min {
                return min
            }
            if let max = max?(),
               fractionalValue > max {
                return max
            }
            return fractionalValue
        case let .viewport(padding):
            return viewportWidth - padding
        }
    }
}

public struct GridColumnConfiguration {
    public let width: GridColumnWidth
    public let style: GridCellStyle

    public init(width: GridColumnWidth, style: GridCellStyle = .init()) {
        self.width = width
        self.style = style
    }
}

public struct GridRowConfiguration {
    public let initialHeight: CGFloat
    public let style: GridCellStyle

    public init(initialHeight: CGFloat, style: GridCellStyle = .init()) {
        self.initialHeight = initialHeight
        self.style = style
    }
}

public struct GradientColors {
    public let primary: UIColor
    public let secondary: UIColor

    public init(primary: UIColor, secondary: UIColor) {
        self.primary = primary
        self.secondary = secondary
    }
}

public struct GridConfiguration {
    public let style: GridStyle
    public let boundsLimitShadowColors: GradientColors

    public let columnsConfiguration: [GridColumnConfiguration]
    public let rowsConfiguration: [GridRowConfiguration]

    public let collapsedColumnWidth: CGFloat
    public let collapsedRowHeight: CGFloat

    /// Ignores optimization to initialize editor within the cell. With optimization, the editor is not initialized until the cell is ready to be rendered on the UI thereby
    /// not incurring any overheads when creating attributedText containing a `GridView` in an attachment. Defaults to `false`.
    public let ignoresOptimizedInit: Bool

    public init(columnsConfiguration: [GridColumnConfiguration],
                rowsConfiguration: [GridRowConfiguration],
                style: GridStyle = .default,
                boundsLimitShadowColors: GradientColors = GradientColors(primary: .black, secondary: .white),
                collapsedColumnWidth: CGFloat = 2,
                collapsedRowHeight: CGFloat = 2,
                ignoresOptimizedInit: Bool = false
    ) {
        self.columnsConfiguration = columnsConfiguration
        self.rowsConfiguration = rowsConfiguration
        self.style = style
        self.boundsLimitShadowColors = boundsLimitShadowColors
        self.collapsedColumnWidth = collapsedColumnWidth
        self.collapsedRowHeight = collapsedRowHeight
        self.ignoresOptimizedInit = ignoresOptimizedInit
    }

    public var numberOfColumns: Int {
        columnsConfiguration.count
    }

    public var numberOfRows: Int {
        rowsConfiguration.count
    }
}
