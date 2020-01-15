//
//  ItalicsCommand.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

public class ItalicsCommand: FontTraitToggleCommand {
    public init() {
        super.init(trait: .traitItalic)
    }
}
