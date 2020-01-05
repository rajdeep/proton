//
//  SnapshotTestAttachment.swift
//  ProtonTests
//
//  Created by Rajdeep Kwatra on 5/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

@testable import Proton

class RichTextViewTestViewController: SnapshotTestViewController {
    let textView: RichTextView

    init() {
        textView = RichTextView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.addBorder()

        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 20),
        ])
    }
}
