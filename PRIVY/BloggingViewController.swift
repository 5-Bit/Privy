//
//  BloggingViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

final class BloggingViewController: FormViewController {
    
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
        // website, wordpress, tumblr, medium
        let websiteRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Web Site"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your website URL"
            PrivyUser.currentUser.userInfo.blogging.website = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.blogging.website = $0
        }
        
        let wordPressRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "WordPress"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your WordPress username"
            PrivyUser.currentUser.userInfo.blogging.wordpress = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.blogging.wordpress = $0
        }
        
        let tumblrRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Tumblr"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Tumblr username"
            PrivyUser.currentUser.userInfo.blogging.tumblr = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.blogging.tumblr = $0
        }
        
        let mediumRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Medium"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Medium username"
            PrivyUser.currentUser.userInfo.blogging.medium = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.blogging.medium = $0
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
        
        let infoSection = SectionFormer(rowFormer: websiteRow, wordPressRow, tumblrRow, mediumRow)
            .set(headerViewFormer: createHeader("Introduction"))
        
        former.append(sectionFormer: infoSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
}
