//
//  SnapshotTestViewController.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

class SnapshotTestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .lightGray
    }

    func render(size: CGSize = CGSize(width: 300, height: 100)) {
        view.frame = CGRect(origin: .zero, size: size)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}
