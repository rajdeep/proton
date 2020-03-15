//
//  FixedWidthAttachmentExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 6/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import Proton
import UIKit

class FixedWidthAttachmentExampleViewController: ExamplesBaseViewController {
    let widthTextField = UITextField()

    var width: CGFloat {
        let width = CGFloat(
            exactly: NumberFormatter().number(from: widthTextField.text ?? "") ?? 100) ?? 100
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
        widthTextField.placeholder = "Width"
        widthTextField.borderStyle = .roundedRect

        view.addSubview(widthTextField)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.leadingAnchor.constraint(equalTo: widthTextField.trailingAnchor, constant: 10),

            widthTextField.topAnchor.constraint(equalTo: button.topAnchor),
            widthTextField.widthAnchor.constraint(equalToConstant: 60),
            widthTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            editor.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
        ])
    }

    @objc
    func insertAttachment(sender: UIButton) {
        let inlineEditor = InlineEditorView()
        inlineEditor.backgroundColor = .systemTeal
        inlineEditor.textColor = .black
        inlineEditor.layer.borderWidth = 1.0
        inlineEditor.layer.cornerRadius = 4.0
        inlineEditor.layer.borderColor = UIColor.black.cgColor
        inlineEditor.clipsToBounds = true

        let attachment = Attachment(inlineEditor, size: .fixed(width: width))
        attachment.selectBeforeDelete = true
        inlineEditor.boundsObserver = attachment
        editor.insertAttachment(in: editor.selectedRange, attachment: attachment)
    }
}

extension FixedWidthAttachmentExampleViewController: AttachmentOffsetProviding {
    func offset(
        for attachment: Attachment, in textContainer: NSTextContainer,
        proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGPoint {
        return CGPoint(x: 0, y: -2)
    }
}
