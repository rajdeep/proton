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
    public let backgroundColor: UIColor = .white
}

public struct GridRowConfiguration {
    public let minRowHeight: CGFloat
    public let maxRowHeight: CGFloat
    public let backgroundColor: UIColor = .white
}

public struct GridConfiguration {
    public let columnsConfiguration: [GridColumnConfiguration]
    public let rowsConfiguration: [GridRowConfiguration]

    public var numberOfColumns: Int {
        columnsConfiguration.count
    }

    public var numberOfRows: Int {
        rowsConfiguration.count
    }
}
