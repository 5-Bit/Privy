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
        }.configure {
            $0.placeholder = "Add your email address"
            $0.text = PrivyUser.currentUser.userInfo.basic.emailAddress
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.emailAddress = $0
        }

        let phoneNumberRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your phone number"
            $0.text = PrivyUser.currentUser.userInfo.basic.phoneNumber
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.basic.phoneNumber = $0
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
        
        let infoSection = SectionFormer(rowFormer: firstNameRow, lastNameRow, emailAddressRow, phoneNumberRow)
            .set(headerViewFormer: createHeader("Introduction"))
        
        former.append(sectionFormer: imageSection, infoSection)
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