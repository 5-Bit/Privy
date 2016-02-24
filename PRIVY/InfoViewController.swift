//
//  InfoTableViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

protocol DynamicTypeCapable: class {
    func register()
    func unregister()
    func handleDynamicFontChange(nofication: NSNotification)
}

extension DynamicTypeCapable where Self: FormViewController {
    func register() {
        NSNotificationCenter.defaultCenter().addObserverForName(
            UIContentSizeCategoryDidChangeNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: handleDynamicFontChange
        )
    }
    
    func unregister() {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil
        )
    }
    
    func handleDynamicFontChange(nofication: NSNotification) {
        former.reload()
    }
}

final class InfoViewContoller: FormViewController {
    
    // MARK: Public
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        former.deselect(true)
    }
    
    // MARK: Private
    private func configure() {
        let backBarButton = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButton
        tableView.contentInset.top = 40
        
        // Create RowFormers
        
        let createMenu: ((String, (() -> Void)?) -> RowFormer) = { text, onSelected in
            return LabelRowFormer<FormLabelCell>() {
                $0.titleLabel.textColor = UIColor.privyDarkBlueColor
                $0.titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle3)
                $0.accessoryType = .DisclosureIndicator
            }.configure {
                $0.text = text
            }.onSelected { _ in
                onSelected?()
            }
        }
        
        let editProfileRow = createMenu("Profile Information") { [weak self] in
            let viewController = BasicInfoViewController()
            viewController.title = "Profile Information"
            self?.navigationController?.pushViewController(viewController, animated: true)
        }
        
        // Create Headers and Footers
        let createHeader: (String -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>()
                .configure {
                    $0.text = text
                    $0.viewHeight = 40
            }
        }
        
        // Create SectionFormers
        let basicSection = SectionFormer(rowFormer: editProfileRow)
            .set(headerViewFormer: createHeader("Profile Information"))

        let socialSection = SectionFormer(rowFormer: editProfileRow)
            .set(headerViewFormer: createHeader("Social Information"))

        let businessSection = SectionFormer(rowFormer: editProfileRow)
            .set(headerViewFormer: createHeader("Business Information"))

        let developerSection = SectionFormer(rowFormer: editProfileRow)
            .set(headerViewFormer: createHeader("Developer Information"))

        let mediaSection = SectionFormer(rowFormer: editProfileRow)
            .set(headerViewFormer: createHeader("Media Information"))

        let bloggingSection = SectionFormer(rowFormer: editProfileRow)
            .set(headerViewFormer: createHeader("Blogging Information"))

        former.append(sectionFormer: basicSection, socialSection, businessSection, developerSection, mediaSection, bloggingSection)
    }
}