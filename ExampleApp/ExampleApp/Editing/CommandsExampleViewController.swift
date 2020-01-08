//
//  CommandsExampleViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 8/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import Foundation
import UIKit

import Proton

class CommandButton: UIButton {
    let command: EditorCommand

    init(command: EditorCommand) {
        self.command = command
        super.init(frame: .zero)

        setTitleColor(.blue, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CommandsExampleViewController: ExamplesBaseViewController {
    let editor = EditorView()
    let commandExecutor = EditorCommandExecutor()

    let commands: [String: EditorCommand] = [
        "Panel": PanelCommand(),
        "Bold": BoldCommand(),
        "Italics": ItalicsCommand()
    ]

    override func setup() {
        super.setup()

        editor.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editor)

        editor.layer.borderColor = UIColor.blue.cgColor
        editor.layer.borderWidth = 1.0

        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false


        for command in commands {
            let button = CommandButton(command: command.value)
            button.setTitle(command.key, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(runCommand(sender:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            editor.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            editor.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            editor.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            editor.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }

    @objc
    func runCommand(sender: CommandButton) {
        commandExecutor.execute(sender.command)
    }
}
