//
//  EditorLineNumberProvider.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 14/7/2023.
//  Copyright © 2023 Rajdeep Kwatra. All rights reserved.
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

/// Describes an object capable of providing numbers to be displayed  when `isLineNumbersEnabled` is set to `true` in `EditorView`
public protocol LineNumberProvider: AnyObject {
    var lineNumberWrappingMarker: String? { get }

    func lineNumberString(for index: Int) -> String?
}
