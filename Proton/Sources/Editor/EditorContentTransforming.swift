//
//  EditorContentEncoding.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 11/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

public protocol EditorContentTransforming {
    associatedtype TransformedType
    func transform(_ content: EditorContent) -> TransformedType!
}
