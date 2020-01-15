//
//  EditorContentEncoding.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 15/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

public protocol EditorContentEncoding {
    associatedtype EncodedType
    func encode(_ content: EditorContent) -> EncodedType!
}
