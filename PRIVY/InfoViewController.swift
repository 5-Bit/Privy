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

final class InfoViewContoller: FormViewController, DynamicTypeCapable {
    
    // MARK: Public
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        former.deselect(true)
        register()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        unregister()
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
        
        let sectionTitles: [String: FormViewController.Type] = [
            "Basic": BasicInfoViewController.self,
            "Social": SocialViewController.self,
            "Business": BusinessViewController.self,
            "Developer": DeveloperViewController.self,
            "Media": MediaViewController.self,
            "Blogging": BloggingViewController.self
        ]
        
        var sections = [RowFormer]()
        sections.reserveCapacity(sectionTitles.count)
        
        for (sectionTitle, vcType) in sectionTitles {
            let row = createMenu(sectionTitle) { [weak self] in
                let viewController = vcType.init()
                viewController.title = sectionTitle
                self?.navigationController?.pushViewController(viewController, animated: true)
            }
            
            sections.append(row)
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
        let userInfoSection = SectionFormer(rowFormers: sections)
            .set(headerViewFormer: createHeader("Your Information"))

        former.append(sectionFormer: userInfoSection)
    }
}