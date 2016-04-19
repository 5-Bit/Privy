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
import KYNavigationProgress

struct Row {
    let title: String
    let description: String
}

struct Section {
    let title: String
    let rows: [Row]
}

final class HistoryUserViewController: UIViewController {
    weak var historyTableViewController: HistoryTableViewController?

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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let selections = tableView.indexPathsForSelectedRows {
            for selectedIndex in selections {
                tableView.deselectRowAtIndexPath(selectedIndex, animated: true)
            }
        }
    }


    override func previewActionItems() -> [UIPreviewActionItem] {
        var actions = [UIPreviewActionItem]()

        actions.append(UIPreviewAction(
            title: "Refresh",
            style: UIPreviewActionStyle.Default,
            handler: { [unowned self] (action, viewController) in
                guard let historyTableVC = self.historyTableViewController else {
                    return
                }

                historyTableVC.fetchHistory { _ in }
        }))

        actions.append(UIPreviewAction(
            title: "Delete",
            style: UIPreviewActionStyle.Destructive,
            handler: { [unowned self] (action, viewController) in
                guard let historyTableVC = self.historyTableViewController else {
                    return
                }

                guard let user = self.user, row = self.allUsers.indexOf(user) else {
                    return
                }

                let indexPath = NSIndexPath(
                    forRow: row,
                    inSection: 0
                )

                historyTableVC.deleteUserAtIndexPath(indexPath)
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
        let contact = applyCurrentUserInfoToContact(CNContact())

        let picker = CNContactViewController(forNewContact: contact)
        picker.delegate = self

        let pickerNavigation = UINavigationController(rootViewController: picker)
        pickerNavigation.view.tintColor = UIColor.privyDarkBlueColor
        presentViewController(pickerNavigation, animated: true, completion: nil)
    }

    private func showContactPicker() {
        let picker = CNContactPickerViewController()
        picker.view.tintColor = UIColor.privyDarkBlueColor

        picker.delegate = self

        presentViewController(picker, animated: true, completion: nil)
    }

    private func applyCurrentUserInfoToContact(contact: CNContact) -> CNContact {
        guard let user = user else {
            return contact
        }

        let workingContact = contact.mutableCopy() as! CNMutableContact

        workingContact.givenName = user.basic.firstName ?? workingContact.givenName
        workingContact.familyName = user.basic.lastName ?? workingContact.familyName

        if let image = profileImageView.image {
            workingContact.imageData = UIImageJPEGRepresentation(image, 0.5)
        }

        if workingContact.phoneNumbers.isEmpty {
            workingContact.phoneNumbers = extractPhoneNumbers()
        } else {
            workingContact.phoneNumbers.appendContentsOf(extractPhoneNumbers())
        }

        if workingContact.emailAddresses.isEmpty {
            workingContact.emailAddresses = extractEmails()
        } else {
            workingContact.emailAddresses.appendContentsOf(extractEmails())
        }

        if let birthDay = user.basic.birthDay,
               calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
            workingContact.birthday = calendar.componentsInTimeZone(
                NSTimeZone.localTimeZone(),
                fromDate: birthDay
            )
        }

        if workingContact.socialProfiles.isEmpty {
            workingContact.socialProfiles = extractSocialProfiles()
        } else {
            workingContact.socialProfiles.appendContentsOf(extractSocialProfiles())
        }

        return workingContact
    }

    private func saveContact(contact: CNMutableContact, shouldCreate create: Bool) {
        let saveRequest = CNSaveRequest()
        if create {
            saveRequest.addContact(contact, toContainerWithIdentifier: "Privy")
        } else {
            saveRequest.updateContact(contact)
        }
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
        for (key, value) in json where key != "location" {
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

            if let sub = value as? [String: AnyObject] {
                for (subKey, subValue) in sub where subKey != "Birthday" {
                    if key != "basic" || (subKey != "First Name" && subKey != "Last Name") {
                        let row = Row(title: subKey.capitalizedString, description: subValue as! String)
                        rows.append(row)
                    }
                }
            } else if let uuid = value as? String where key == "uuid" {
                navigationController?.setProgress(0.25, animated: true)
                RequestManager.sharedManager.fetchProfilePictureForUser(uuid) { image in
                    self.navigationController?.setProgress(0.25, animated: true)
                    self.profileImageView.image = image

                    if image == nil {
                        self.navigationController?.cancelProgress()
                    } else {
                        self.navigationController?.finishProgress()
                    }
                }
            }

            if !rows.isEmpty {
                sections.append(Section(title: key.capitalizedString, rows: rows))
            }
        }

        accounts = sections.sort {
            $0.title < $1.title
        }
    }

    private func extractPhoneNumbers() -> [CNLabeledValue] {
        var phoneNumbers = [CNLabeledValue]()

        guard let user = user else {
            return phoneNumbers
        }

        if !user.basic.phoneNumber.isNilOrEmpty {
            phoneNumbers.append(
                CNLabeledValue(
                    label: CNLabelHome,
                    value: CNPhoneNumber(
                        stringValue: user.basic.phoneNumber!
                    )
                )
            )
        }

        if !user.business.phoneNumber.isNilOrEmpty {
            phoneNumbers.append(
                CNLabeledValue(
                    label: CNLabelWork,
                    value: CNPhoneNumber(
                        stringValue: user.business.phoneNumber!
                    )
                )
            )
        }

        return phoneNumbers
    }


    private func extractEmails() -> [CNLabeledValue] {
        var emails = [CNLabeledValue]()

        guard let user = user else {
            return emails
        }

        if !user.basic.emailAddress.isNilOrEmpty {
            emails.append(
                CNLabeledValue(
                    label: CNLabelHome,
                    value: user.basic.emailAddress!
                )
            )
        }

        if !user.business.emailAddress.isNilOrEmpty {
            emails.append(
                CNLabeledValue(
                    label: CNLabelWork,
                    value: user.business.emailAddress!
                )
            )
        }

        return emails
    }

    private func extractSocialProfiles() -> [CNLabeledValue] {
        var profiles = [CNLabeledValue]()

        guard let user = user else {
            return profiles
        }

        if !user.social.twitter.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: CNSocialProfileServiceTwitter,
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.social.twitter,
                        userIdentifier: nil,
                        service: CNSocialProfileServiceTwitter
                    )
                )
            )
        }

        if !user.social.facebook.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: CNSocialProfileServiceFacebook,
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.social.facebook,
                        userIdentifier: nil,
                        service: CNSocialProfileServiceFacebook
                    )
                )
            )
        }

        if !user.social.instagram.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "Instagram",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.social.instagram,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        if !user.social.snapchat.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "Snapchat",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.social.snapchat,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        if !user.media.flickr.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: CNSocialProfileServiceFlickr,
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.media.flickr,
                        userIdentifier: nil,
                        service: CNSocialProfileServiceFlickr
                    )
                )
            )
        }

        if !user.media.pintrest.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "Pintrest",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.media.pintrest,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        if !user.media.soundcloud.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "Sound Cloud",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.media.soundcloud,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        if !user.media.vimeo.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "Vimeo",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.media.vimeo,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        if !user.media.vine.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "Vine",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.media.vine,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        if !user.media.youtube.isNilOrEmpty {
            profiles.append(
                CNLabeledValue(
                    label: "YouTube",
                    value: CNSocialProfile(
                        urlString: nil,
                        username: user.media.youtube,
                        userIdentifier: nil,
                        service: nil
                    )
                )
            )
        }

        return profiles
    }

    private func openRow(row: Row) {
        let schemes = [
            "Phone Number"      :   "tel:",
            "Email Address"     :   "mailto:",
            "Github"            :   "https://github.com/",
            "Stackoverflow"     :   "https://stackoverflow.com/users/",
            "Twitter"           :   "https://twitter.com/",
            "Facebook"          :   "https://facebook.com/",
            "Googleplus"        :   "https://plus.google.com/",
        ]

        guard let scheme = schemes[row.title],
            description = row.description.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()),
                url = NSURL(string: scheme + description) else {
            return
        }

        UIApplication.sharedApplication().openURL(url)
    }
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

extension HistoryUserViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alertController = UIAlertController(
            title: "Warning",
            message: "You are about to leave Privy. Are you sure?",
            preferredStyle: .Alert
        )

        let continueAction = UIAlertAction(
            title: "Continue",
            style: .Default) { [unowned self] action in
                self.openRow(self.accounts[indexPath.section].rows[indexPath.row])
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .Cancel) { _ in
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        alertController.addAction(continueAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
}


extension HistoryUserViewController: CNContactViewControllerDelegate {
    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
        viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        guard let contact = contact as? CNMutableContact else {
            return
        }

        saveContact(contact, shouldCreate: true)
    }
}

extension HistoryUserViewController: CNContactPickerDelegate {
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        guard let contact = applyCurrentUserInfoToContact(contact).mutableCopy() as? CNMutableContact else {
            return
        }

        saveContact(contact, shouldCreate: false)
    }
}

