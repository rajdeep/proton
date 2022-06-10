//
//  GridConfiguration.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 6/6/2022.
//  Copyright © 2022 Rajdeep Kwatra. All rights reserved.
//

import Foundation

public enum GridColumnDimension {
    case fixed(CGFloat)
    case fractional(CGFloat)

    public func value(basedOn total: CGFloat) -> CGFloat {
        switch self {
        case .fixed(let value):
            return value
        case .fractional(let value):
            return value * total
        }
    }
}

public struct GridColumnConfiguration {
    public let dimension: GridColumnDimension
    public let style: GridCellStyle

    public init(dimension: GridColumnDimension, style: GridCellStyle = .init()) {
        self.dimension = dimension
        self.style = style
    }
}

public struct GridRowConfiguration {
    public let minRowHeight: CGFloat
    public let maxRowHeight: CGFloat
    public let style: GridCellStyle

    public init(minRowHeight: CGFloat, maxRowHeight: CGFloat, style: GridCellStyle = .init()) {
        self.minRowHeight = minRowHeight
        self.maxRowHeight = maxRowHeight
        self.style = style
    }
}

public struct GridConfiguration {
    public let columnsConfiguration: [GridColumnConfiguration]
    public let rowsConfiguration: [GridRowConfiguration]

    public init(columnsConfiguration: [GridColumnConfiguration], rowsConfiguration: [GridRowConfiguration]) {
        self.columnsConfiguration = columnsConfiguration
        self.rowsConfiguration = rowsConfiguration
    }

    public var numberOfColumns: Int {
        columnsConfiguration.count
    }

    public var numberOfRows: Int {
        rowsConfiguration.count
    }
}
