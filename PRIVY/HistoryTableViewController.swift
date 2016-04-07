//
//  HistoryTableViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

typealias HistoryUser = InfoTypes

class HistoryTableViewController: UITableViewController {
    var datasource = LocalStorage.defaultStorage.loadHistory() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                if self.tabBarController?.tabBar.selectedItem === self.navigationController?.tabBarItem {
                    if oldValue.count == self.datasource.count {
                        self.tableView.reloadSections(
                            NSIndexSet(index: 0),
                            withRowAnimation: .None
                        )
                    } else {
                        self.tableView.reloadSections(
                            NSIndexSet(index: 0),
                            withRowAnimation: .Top
                        )
                    }
                }

                LocalStorage.defaultStorage.saveHistory(self.datasource)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelectionDuringEditing = false
        tableView.allowsMultipleSelection = false

        clearsSelectionOnViewWillAppear = true

        navigationItem.rightBarButtonItem = self.editButtonItem()


        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .privyDarkBlueColor
        refreshControl.addTarget(
            self,
            action: #selector(HistoryTableViewController.refreshControlTriggered(_:)),
            forControlEvents: UIControlEvents.ValueChanged
        )
        tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        datasource = LocalStorage.defaultStorage.loadHistory()
        print(datasource)
        tableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.tabBarItem.badgeValue = nil
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc private func refreshControlTriggered(refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        print("refreshing")

        fetchHistory { _ in
            refreshControl.endRefreshing()
        }
    }

    func fetchHistory(completion: (success: Bool) -> Void) {
        RequestManager.sharedManager.refreshHistory { (history, errorStatus) in
            if let history = history {
                self.datasource = history
            }

            completion(success: errorStatus == .Ok)
        }
    }

    private func countInfo(user: HistoryUser) -> Int {
        let types = [
            user.basic.emailAddress, user.basic.phoneNumber, String(user.basic.birthDay),
            user.basic.addressLine1, user.basic.addressLine2, user.basic.city, user.basic.country,
            user.basic.postalCode, user.blogging.medium,
            user.blogging.tumblr, user.blogging.website, user.blogging.wordpress,
            user.business.emailAddress, user.business.linkedin, user.business.phoneNumber,
            user.developer.bitbucket, user.developer.github, user.developer.stackoverflow,
            user.media.flickr, user.media.pintrest, user.media.soundcloud, user.media.vimeo,
            user.media.vine, user.media.youtube, user.social.facebook, user.social.googlePlus,
            user.social.instagram, user.social.snapchat, user.social.twitter
        ]

        return types.flatMap({ $0 }).count
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("historyCell", forIndexPath: indexPath)

        let user = datasource[indexPath.row]

        cell.textLabel?.text = (user.basic.firstName ?? "") + " " + (user.basic.lastName ?? "")

        let count = countInfo(user)
        let countPhrase = count == 1 ? "method" : "methods"

        cell.detailTextLabel?.text = "\(count) contact \(countPhrase)"

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {

        }
    }

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let userViewController = segue.destinationViewController as? HistoryUserViewController,
            indexPath = tableView.indexPathForCell(sender as! UITableViewCell) else {

            return
        }

        userViewController.user = datasource[indexPath.row]
    }
}
