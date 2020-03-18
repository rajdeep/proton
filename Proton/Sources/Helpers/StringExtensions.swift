//
//  StringExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 18/3/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation

extension String {
    var isBackspace: Bool {
        guard let char = cString(using: String.Encoding.utf8) else {
            return false
        }
        let isBackSpace = strcmp(char, "\\b")
        return isBackSpace == -92
    }
}
