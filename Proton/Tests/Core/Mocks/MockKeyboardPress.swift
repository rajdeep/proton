//
//  MockKeyboardPress.swift
//  ProtonTests
//
//  Created by Hon Thi on 6/10/2023.
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

import UIKit

@available(iOS 13.4, *)
class MockUIPress: UIPress {
    private let _characters: String
    override var key: UIKey? {
        MockUIKey(characters: _characters)
    }

    init(characters: String) {
        self._characters = characters
    }
}

@available(iOS 13.4, *)
class MockUIKey: UIKey {
    private let _characters: String
    override var charactersIgnoringModifiers: String { _characters }

    init(characters: String) {
        self._characters = characters
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
