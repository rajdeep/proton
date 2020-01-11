//
//  MasterViewController.swift
//  ExampleApp
//
//  Created by Rajdeep Kwatra on 2/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//

import UIKit

struct Navigation {
    let title: String
    let items: [NavigationItem]
}

struct NavigationItem {
    let title: String
    let viewController: UIViewController
}

class MasterViewController: UITableViewController {

    let navigation = [
        Navigation(title: "Basic features",
                   items: [
                    NavigationItem(title: "Autogrowing Editor", viewController: AutogrowingEditorViewExampleViewController()),
        ]),
        Navigation(title: "Attachment",
                   items: [
                    NavigationItem(title: "Match Content", viewController: MatchContentAttachmentExampleViewController()),
                    NavigationItem(title: "Full Width", viewController: FullWidthAttachmentExampleViewController()),
                    NavigationItem(title: "Fixed Width", viewController: FixedWidthAttachmentExampleViewController()),
                    NavigationItem(title: "Width Range", viewController: WidthRangeAttachmentExampleViewController()),
                    NavigationItem(title: "Percent Width", viewController: PercentWidthAttachmentExampleViewController()),
        ]),
        Navigation(title: "Advanced features",
                   items: [
                    NavigationItem(title: "Commands", viewController: CommandsExampleViewController()),
                    NavigationItem(title: "Text Processors", viewController: TextProcessorExampleViewController()),
        ]),
    ]

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return navigation.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        navigation[section].title
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return navigation[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = navigation.item(at: indexPath).title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = navigation.item(at: indexPath)
        let viewController = item.viewController
        viewController.title = item.title
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension Array where Element == Navigation {
    func item(at indexPath: IndexPath) -> NavigationItem {
        return self[indexPath.section].items[indexPath.row]
    }
}
