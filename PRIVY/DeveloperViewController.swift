//
//  DeveloperViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

final class DeveloperViewController: FormViewController {
    
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
        
        let githubRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "GitHub"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your GitHub username"
            $0.text = PrivyUser.currentUser.userInfo.developer.github
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.developer.github = $0
        }
        
        let stackOverflowRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Email"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Stack Overflow username"
            $0.text = PrivyUser.currentUser.userInfo.developer.stackoverflow
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.developer.stackoverflow = $0
        }
        
        let bitBucketRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Phone"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Bitbucket username"
            $0.text = PrivyUser.currentUser.userInfo.developer.bitbucket
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.developer.bitbucket = $0
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
        
        let infoSection = SectionFormer(rowFormer: githubRow, stackOverflowRow, bitBucketRow)
            .set(headerViewFormer: createHeader("Introduction"))
        
        former.append(sectionFormer: infoSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
}
