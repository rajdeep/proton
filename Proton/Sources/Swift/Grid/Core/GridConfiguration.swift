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
    public let initialHeight: CGFloat
    public let style: GridCellStyle

    public init(initialHeight: CGFloat, style: GridCellStyle = .init()) {
        self.initialHeight = initialHeight
        self.style = style
    }
}

public struct GridConfiguration {
    public let style: GridStyle
    public let accessory: GridAccessory

    public let columnsConfiguration: [GridColumnConfiguration]
    public let rowsConfiguration: [GridRowConfiguration]

    public init(columnsConfiguration: [GridColumnConfiguration], rowsConfiguration: [GridRowConfiguration], style: GridStyle = .default, accessory: GridAccessory = .init()) {
        self.columnsConfiguration = columnsConfiguration
        self.rowsConfiguration = rowsConfiguration
        self.style = style
        self.accessory = accessory
    }

    public var numberOfColumns: Int {
        columnsConfiguration.count
    }

    public var numberOfRows: Int {
        rowsConfiguration.count
    }
}

public struct GridAccessory {
    public let resizeColumnHandleImage: UIImage?
    public let deleteColumnButtonImage: UIImage?
    public let deleteRowButtonImage: UIImage?
    public let addColumnButtonImage: UIImage?
    public let addRowButtonImage: UIImage?

    public init(
        resizeColumnHandleImage: UIImage? = nil,
        deleteColumnButtonImage: UIImage? = nil,
        deleteRowButtonImage: UIImage? = nil,
        addColumnButtonImage: UIImage? = nil,
        addRowButtonImage: UIImage? = nil
    ){
        self.resizeColumnHandleImage = resizeColumnHandleImage
        self.deleteColumnButtonImage = deleteColumnButtonImage
        self.deleteRowButtonImage = deleteRowButtonImage
        self.addColumnButtonImage = addColumnButtonImage
        self.addRowButtonImage = addRowButtonImage
    }
}
