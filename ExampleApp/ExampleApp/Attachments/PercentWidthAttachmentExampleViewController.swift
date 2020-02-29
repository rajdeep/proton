//
//  PercentWidthAttachmentExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class PercentWidthAttachmentExampleViewController: ExamplesBaseViewController {
    let widthTextField = UITextField()

    var width: CGFloat {
        let width = CGFloat(exactly: NumberFormatter().number(from: widthTextField.text ?? "") ?? 50) ?? 50
        return width
    }

    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.systemBlue.cgColor
        editor.layer.borderWidth = 1.0

        let button = UIButton(type: .system)
        button.setTitle("Insert attachment", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(insertAttachment(sender:)), for: .touchUpInside)

        view.addSubview(button)

        widthTextField.translatesAutoresizingMaskIntoConstraints = false
        widthTextField.placeholder = "Percent"
        widthTextField.borderStyle = .roundedRect

        view.addSubview(widthTextField)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: widthTextField.trailingAnchor, constant: 10),

            widthTextField.topAnchor.constraint(equalTo: button.topAnchor),
            widthTextField.widthAnchor.constraint(equalToConstant: 80),
            widthTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            editor.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }

    @objc
    func insertAttachment(sender: UIButton) {
        let textField = AutogrowingTextField()
        textField.backgroundColor = .systemTeal
        textField.textColor = .black
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 4.0
        textField.layer.borderColor = UIColor.black.cgColor
        textField.font = editor.font

        let attachment = Attachment(textField, size: .percent(width: width))
        textField.boundsObserver = attachment
        attachment.offsetProvider = self
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    }
}

extension PercentWidthAttachmentExampleViewController: AttachmentOffsetProviding {
    func offset(for attachment: Attachment, in textContainer: NSTextContainer, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGPoint {
        return CGPoint(x: 0, y: -2)
    }
}
