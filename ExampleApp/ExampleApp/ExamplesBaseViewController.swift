//
//  ExamplesBaseViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 2/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class ExamplesBaseViewController: UIViewController {

    let editor = EditorView()

    func setup() {
        self.view.backgroundColor = .secondarySystemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        editor.setFocus()
    }
}
