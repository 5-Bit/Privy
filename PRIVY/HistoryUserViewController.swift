//
//  HistoryUserViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 3/30/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import ObjectMapper
import Contacts
import ContactsUI
import CoreLocation

struct Row {
    let title: String
    let description: String
}

struct Section {
    let title: String
    let rows: [Row]
}

class HistoryUserViewController: UIViewController {
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var locationButton: UIButton!

    var allUsers = [HistoryUser]()

    private var user: HistoryUser?

    private var accounts = [Section]() {
        didSet {
            if let tableView = tableView {
                tableView.reloadData()
            }

            numberOfAccounts = accounts.reduce(0) {
                $0 + $1.rows.count
            }
        }
    }

    var userIndex: Int? {
        didSet {
            user = userIndex != nil ? allUsers[userIndex!] : nil
        }
    }

    internal private(set) var numberOfAccounts = 0 {
        didSet {
            let phrase = numberOfAccounts == 1 ? "account" : "accounts"
            detailLabel.text = "\(numberOfAccounts) \(phrase)"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        generateDataSource()
        tableView.tableHeaderView?.frame.size.height = 200

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Save,
            target: self,
            action: #selector(HistoryUserViewController.addButtonTapped(_:))
        )
    }

    override func previewActionItems() -> [UIPreviewActionItem] {
        var actions = [UIPreviewActionItem]()

        actions.append(UIPreviewAction(
            title: "Refresh",
            style: UIPreviewActionStyle.Default,
            handler: { (action, viewController) in
                print("handled")
        }))

        actions.append(UIPreviewAction(
            title: "Delete",
            style: UIPreviewActionStyle.Destructive,
            handler: { (action, viewController) in
                print("handled")
        }))

        return actions
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction private func locationButtonTapped(button: UIButton) {
        performSegueWithIdentifier("showLocations", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let dest = segue.destinationViewController as? MapViewController
            where segue.identifier == "showLocations" else {
                return
        }

        dest.allUsers = allUsers
        dest.currentUserIndex = userIndex
    }

    @objc private func addButtonTapped(barButton: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "",
            message: "How would you like to save this contact",
            preferredStyle: .ActionSheet
        )

        let addNewAction = UIAlertAction(
            title: "Create New Contact",
            style: UIAlertActionStyle.Default) { [unowned self] action in
                self.showSavePicker()
        }

        let addToExistingAction = UIAlertAction(
            title: "Add to Existing Contact",
            style: .Default) { [unowned self] action in
                self.showContactPicker()
        }

        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: nil
        )

        alertController.addAction(addNewAction)
        alertController.addAction(addToExistingAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    private func showSavePicker() {
        guard let user = user else {
            return
        }

        let contact = CNMutableContact()

        contact.givenName = user.basic.firstName ?? ""
        contact.familyName = user.basic.lastName ?? ""

        contact.emailAddresses = extractEmails()


        let picker = CNContactViewController(forNewContact: contact)
        picker.delegate = self

        let pickerNavigation = UINavigationController(rootViewController: picker)
        pickerNavigation.view.tintColor = UIColor.privyDarkBlueColor
        presentViewController(pickerNavigation, animated: true, completion: nil)
    }

    private func showContactPicker() {

        let picker = CNContactViewController()
        picker.delegate = self

        presentViewController(picker, animated: true, completion: nil)
    }

    /**
     <#Description#>
     */
    private func generateDataSource() {
        guard let user = user else {
            accounts = [Section]()
            return
        }

        let json = Mapper<HistoryUser>().toJSON(user)

        locationButton.hidden = user.location?.longitude == nil || user.location?.latitude == nil

        var sections = [Section]()
        for (key, value) in json as! [String: [String: AnyObject]] where key != "location" {
            var rows = [Row]()

            if key == "basic" {
                var names = [String]()

                if let firstName = value["First Name"] as? String {
                    if let lastName = value["Last Name"] as? String {
                        names.append(firstName)
                        names.append(lastName)
                    } else {
                        names.append(firstName)
                    }
                } else {
                    if let lastName = value["Last Name"] as? String {
                        names.append(lastName)
                    }
                }

                nameLabel.text = names.joinWithSeparator(" ")
            }

            for (subKey, subValue) in value where subKey != "Birthday" {
                if key != "basic" || (subKey != "First Name" && subKey != "Last Name") {
                    let row = Row(title: subKey.capitalizedString, description: subValue as! String)
                    rows.append(row)
                }
            }

            if !rows.isEmpty {
                sections.append(Section(title: key, rows: rows))
            }
        }

        accounts = sections.sort {
            $0.title < $1.title
        }
    }

    private func extractEmails() -> [CNLabeledValue] {
        var emails = [CNLabeledValue]()

        guard let user = user else {
            return emails
        }

        if !user.basic.emailAddress.isNilOrEmpty {
            emails.append(CNLabeledValue(label: CNLabelHome, value: user.basic.emailAddress!))
        }

        if !user.business.emailAddress.isNilOrEmpty {
            emails.append(CNLabeledValue(label: CNLabelWork, value: user.business.emailAddress!))
        }

        return emails
    }
}

extension HistoryUserViewController: UITableViewDelegate {
//    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }

//    func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
//        return 200
//    }

//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return UITableViewAutomaticDimension
//    }
//
//    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        return 44.0
//    }
}

extension HistoryUserViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return accounts.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts[section].rows.count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return accounts[section].title
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userInfoCell", forIndexPath: indexPath)

        let account = accounts[indexPath.section].rows[indexPath.row]

        cell.textLabel?.text = account.title
        cell.detailTextLabel?.text = account.description

        return cell
    }
}

extension HistoryUserViewController: CNContactViewControllerDelegate {
    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
        viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)

        if let contact = contact as? CNMutableContact { // Selected done
            saveContact(contact)
        }
    }

    private func saveContact(contact: CNMutableContact) {
        let saveRequest = CNSaveRequest()
        saveRequest.addContact(contact, toContainerWithIdentifier: nil)
    }

//    func contactViewController(viewController: CNContactViewController, shouldPerformDefaultActionForContactProperty property: CNContactProperty) -> Bool {
//        
//    }
}
