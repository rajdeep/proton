//
//  MockListDelegate.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/6/20.
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

import Proton

class MockListFormattingProvider: EditorListFormattingProvider {

    let sequenceGenerators: [SequenceGenerator]
    let listLineFormatting: LineFormatting

    private let defaultSequenceGenerators: [SequenceGenerator]  =
        [NumericSequenceGenerator(),
         DiamondBulletSequenceGenerator(),
         SquareBulletSequenceGenerator()]

    init(sequenceGenerators: [SequenceGenerator] = [], listLineFormatting: LineFormatting? = nil) {
        self.sequenceGenerators = sequenceGenerators.count > 0 ? sequenceGenerators : defaultSequenceGenerators
        self.listLineFormatting = listLineFormatting ?? LineFormatting(indentation: 25, spacingBefore: 0)
    }

    func listLineMarkerFor(editor: EditorView, index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker {
        let sequenceGenerator = self.sequenceGenerators[(level - 1) % self.sequenceGenerators.count]
        let value =  sequenceGenerator.value(at: index)
        return value
    }
}
