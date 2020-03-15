//
//  AttachmentMatchContentExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class MatchContentAttachmentExampleViewController: ExamplesBaseViewController {
    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0

        if let font = UIFont(name: "Papyrus", size: UIFont.labelFontSize) {
            editor.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
        }
        let button = UIButton(type: .system)
        button.setTitle("Insert attachment", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(insertAttachment(sender:)), for: .touchUpInside)

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            editor.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
    }

    @objc
    func insertAttachment(sender _: UIButton) {
        let textField = AutogrowingTextField()
        textField.backgroundColor = .systemTeal
        textField.textColor = .black
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 4.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.font = editor.font

        let attachment = Attachment(textField, size: .matchContent)
        textField.boundsObserver = attachment
        attachment.offsetProvider = self
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    }
}

extension MatchContentAttachmentExampleViewController: AttachmentOffsetProviding {
    func offset(for _: Attachment, in _: NSTextContainer, proposedLineFragment _: CGRect, glyphPosition _: CGPoint, characterIndex _: Int) -> CGPoint {
        CGPoint(x: 0, y: -8)
    }
}
