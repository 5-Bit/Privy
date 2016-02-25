//
//  SocialViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

final class SocialViewController: FormViewController {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        PrivyUser.currentUser.saveChangesToUserInfo()
    }

    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        tableView.contentInset.top = 40
        tableView.contentInset.bottom = 40
        
        // Create RowFomers

        let facebookRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Facebook"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Facebook account ID"
            $0.text = PrivyUser.currentUser.userInfo.social.facebook
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.social.facebook = $0
        }
        
        let twitterRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Twitter"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Twitter account ID"
            $0.text = PrivyUser.currentUser.userInfo.social.twitter
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.social.twitter = $0
        }
        
        let googlePlusRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Google+"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Google+ account ID"
            $0.text = PrivyUser.currentUser.userInfo.social.googlePlus
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.social.googlePlus = $0
        }
        
        let instagramRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Instagram"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Instagram account ID"
            $0.text = PrivyUser.currentUser.userInfo.social.instagram
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.social.instagram = $0
        }

        let snapchatRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Snapchat"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Snapchat account ID"
            $0.text = PrivyUser.currentUser.userInfo.social.snapchat
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.social.snapchat = $0
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
        
        let infoSection = SectionFormer(rowFormer: facebookRow, twitterRow, googlePlusRow, instagramRow, snapchatRow)
            .set(headerViewFormer: createHeader("Introduction"))
        
        former.append(sectionFormer: infoSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
}
