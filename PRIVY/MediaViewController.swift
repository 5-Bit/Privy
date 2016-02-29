//
//  MediaViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

final class MediaViewController: FormViewController {
    
    // MARK: Public
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        PrivyUser.currentUser.saveChangesToUserInfo(true)
    }

    // MARK: Private
    
    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)
    
    private func configure() {
        tableView.contentInset.top = 40
        tableView.contentInset.bottom = 40
        
        // Create RowFomers
        // flickr, soundcloud, youtube, vine, vimeo, pintrest
        let flickrRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Flickr"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Flickr username"
            PrivyUser.currentUser.userInfo.media.flickr = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.media.flickr = $0
        }
        
        let soundCloudRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "SoundCloud"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your SoundCloud username"
            PrivyUser.currentUser.userInfo.media.soundcloud = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.media.soundcloud = $0
        }
        
        let youtubeRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "YouTube"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your YouTube username"
            PrivyUser.currentUser.userInfo.media.youtube = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.media.youtube = $0
        }
        
        let vineRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Vine"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Vine username"
            PrivyUser.currentUser.userInfo.media.vine = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.media.vine = $0
        }

        let vimeoRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Vimeo"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Vimeo username"
            PrivyUser.currentUser.userInfo.media.vimeo = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.media.vimeo = $0
        }

        let pintrestRow = TextFieldRowFormer<ProfileFieldCell>(instantiateType: .Nib(nibName: "ProfileFieldCell")) { [weak self] in
            $0.titleLabel.text = "Pintrest"
            $0.textField.inputAccessoryView = self?.formerInputAccessoryView
        }.configure {
            $0.placeholder = "Add your Pintrest username"
            PrivyUser.currentUser.userInfo.media.pintrest = $0.text
        }.onTextChanged {
            PrivyUser.currentUser.userInfo.media.pintrest = $0
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
        
        let infoSection = SectionFormer(rowFormer: flickrRow, soundCloudRow, youtubeRow, vineRow, vimeoRow, pintrestRow)
            .set(headerViewFormer: createHeader("Introduction"))
        
        former.append(sectionFormer: infoSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }
}
