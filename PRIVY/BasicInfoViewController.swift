//
//  BasicInfoViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

final class BasicInfoViewController: FormViewController {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private lazy var imageRow: LabelRowFormer<ProfileImageCell> = {
        LabelRowFormer<ProfileImageCell>(instantiateType: .Nib(nibName: "ProfileImageCell")) { _ in
//          $0.iconView.image = Profile.sharedInstance.image
        }.configure {
            $0.text = "Choose profile image from library"
            $0.rowHeight = 60
        }.onSelected { [weak self] _ in
            self?.former.deselect(true)
            self?.presentImagePicker()
        }
    }()
    
    private func configure() {
        tableView.contentInset.top = 40
        tableView.contentInset.bottom = 40
        
        // Create RowFomers
        
        let firstNameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "First Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your first name"
            $0.text = PrivyUser.currentUser.userInfo.basic.firstName
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.firstName = $0
        }

        let lastNameRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Last Name"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your last name"
            $0.text = PrivyUser.currentUser.userInfo.basic.lastName
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.lastName = $0
        }

        let emailAddressRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            $0.textField.keyboardType = .EmailAddress
        }.configure {
            $0.placeholder = "Add your email address"
            $0.text = PrivyUser.currentUser.userInfo.basic.emailAddress
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.emailAddress = $0
        }

        let phoneNumberRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            $0.textField.keyboardType = .NumberPad
        }.configure {
            $0.placeholder = "Add your phone number"
            $0.text = PrivyUser.currentUser.userInfo.basic.phoneNumber
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.phoneNumber = $0
        }

        let birthdayRow = InlineDatePickerRowFormer<ProfileLabelCell>(instantiateType: .Nib(nibName: "ProfileLabelCell")) {
            $0.titleLabel.text = "Birthday"
        }.configure {
            $0.date = PrivyUser.currentUser.userInfo.basic.birthDay ?? NSDate()
        }.inlineCellSetup {
                $0.datePicker.datePickerMode = .Date
        }.displayTextFromDate {
                return String.mediumDateNoTime($0)
        }.onDateChanged {
            print($0)
            PrivyUser.currentUser.userInfo.basic.birthDay = $0
        }

        let addressLine1Row = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Address"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Address Line 1"
            $0.text = PrivyUser.currentUser.userInfo.basic.addressLine1
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.addressLine1 = $0
        }

        let addressLine2Row = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Address"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Address Line 2"
            $0.text = PrivyUser.currentUser.userInfo.basic.addressLine2
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.addressLine2 = $0
        }

        let cityRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "City"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your city"
            $0.text = PrivyUser.currentUser.userInfo.basic.city
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.city = $0
        }

        let stateRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "State"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your state"
            $0.text = PrivyUser.currentUser.userInfo.basic.state
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.state = $0
        }

        let countryRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Country"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your country"
            $0.text = PrivyUser.currentUser.userInfo.basic.country
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.country = $0
        }

        let postalCodeRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Zip Code"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
            $0.textField.keyboardType = .NumberPad
        }.configure {
            $0.placeholder = "Add your zip code"
            $0.text = PrivyUser.currentUser.userInfo.basic.postalCode
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.postalCode = $0
        }

        // Create Headers
        let createHeader: (String -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>()
                .configure {
                    $0.viewHeight = 40
                    $0.text = text
            }
        }
        
        // Create SectionFormers
        let imageSection = SectionFormer(rowFormer: imageRow)
            .set(headerViewFormer: createHeader("Profile Image"))
        
        let infoSection = SectionFormer(
            rowFormer: firstNameRow, lastNameRow, emailAddressRow, phoneNumberRow, birthdayRow
        ).set(headerViewFormer: createHeader("Basic Information"))

        let addressSection = SectionFormer(
            rowFormer: addressLine1Row, addressLine2Row, cityRow, stateRow, countryRow, postalCodeRow
        ).set(headerViewFormer: createHeader("Address"))

        former.append(sectionFormer: imageSection, infoSection, addressSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
    
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .PhotoLibrary
        picker.allowsEditing = false
        presentViewController(picker, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        PrivyUser.currentUser.saveChangesToUserInfo(true)
    }
}

extension BasicInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true, completion: nil)
//        Profile.sharedInstance.image = image
        imageRow.cell.progressIndicator.startAnimating()
        imageRow.cellUpdate {
            $0.iconView.image = image
        }

        RequestManager.sharedManager.uploadUserProfilePicture(image) { success in
            self.imageRow.cell.progressIndicator.stopAnimating()
        }
    }
}