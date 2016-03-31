//
//  HistoryUserViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 3/30/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import ObjectMapper

struct Row {
    let title: String
    let description: String
}

struct Section {
    let rows: [Row]
}

class HistoryUserViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    var user: HistoryUser! {
        didSet {
            generateDataSource()
        }
    }

    var accounts = [Section]() {
        didSet {
            if let tableView = tableView {
                tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func generateDataSource() {
        guard let user = user else {
            return
        }

        let json = Mapper<HistoryUser>().toJSON(user)

        var sections = [Section]()
        for (key, value) in json {
            if key == "basic" {
                continue
            }
            var rows = [Row]()

            for (subKey, subValue) in value as! [String: String] {
                rows.append(Row(title: subKey, description: subValue))
            }

            sections.append(Section(rows: rows))
        }

        accounts = sections
    }
}

extension HistoryUserViewController: UITableViewDelegate {

}

extension HistoryUserViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return accounts.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts[section].rows.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userInfoCell", forIndexPath: indexPath)

        let account = accounts[indexPath.section].rows[indexPath.row]

        cell.textLabel?.text = account.title
        cell.detailTextLabel?.text = account.description

        return cell
    }
}


