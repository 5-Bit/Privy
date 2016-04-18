//
//  SettingsViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 3/30/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import Former

final class SettingsViewController: FormViewController {
    lazy var fonts: [UIFont] = self.generateFonts()

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    // MARK: Private

    private lazy var formerInputAccessoryView: FormerInputAccessoryView = FormerInputAccessoryView(former: self.former)


    private func configure() {
        tableView.contentInset.top = 40
        tableView.contentInset.bottom = 40

        // Create RowFomers
        let previewRow = CustomRowFormer<PreviewCell>(instantiateType: .Nib(nibName: "PreviewCell")) {
            print($0)
            
//            $0.title = "Dynamic height"
//            $0.body = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
////            $0.bodyColor = colors[0]
            let basicInfo = PrivyUser.currentUser.userInfo.basic

            if let first = basicInfo.firstName, last = basicInfo.lastName {
                $0.nameLabel.text = "\(first) \(last)"
            } else {
                $0.nameLabel.text = nil
            }

            var candidates = [
                basicInfo.emailAddress, basicInfo.phoneNumber,
            ]

            let socialInfo = PrivyUser.currentUser.userInfo.social

            if let twitter = socialInfo.twitter {
                candidates.append("@" + twitter)
            } else {
                if let googlePlus = socialInfo.googlePlus {
                    candidates.append("+" + googlePlus)
                } else {
                    candidates.append(socialInfo.snapchat ?? socialInfo.instagram ?? socialInfo.facebook)
                }
            }

            let bloggingInfo = PrivyUser.currentUser.userInfo.blogging
            candidates.append(bloggingInfo.website ?? bloggingInfo.wordpress ?? bloggingInfo.tumblr ?? bloggingInfo.medium)

            let mediaInfo = PrivyUser.currentUser.userInfo.media
            candidates.append(mediaInfo.youtube ?? mediaInfo.vimeo ?? mediaInfo.vine ?? mediaInfo.soundcloud ?? mediaInfo.flickr ?? mediaInfo.pintrest)

            let devInfo = PrivyUser.currentUser.userInfo.developer
            candidates.append(devInfo.github ?? devInfo.stackoverflow ?? devInfo.bitbucket)

            var flattened = candidates.flatMap { $0 }

            let fields = [$0.secondLabel, $0.thirdLabel, $0.fourthLabel]
            
            for field in fields {
                if flattened.count > 0 {
                    field.text = flattened.removeFirst()
                } else {
                    field.text = nil
                }
            }

            }.configure {
                $0.rowHeight = 152.0

                let primary = ThemeManager.defaultManager.defaultTheme.primaryColor
                let secondary = ThemeManager.defaultManager.defaultTheme.secondaryColor

                $0.cell.primaryColor = primary
                $0.cell.secondaryColor = secondary

                let defaults = NSUserDefaults.standardUserDefaults()

                if let fontName = defaults.objectForKey("userFontName") as? String,
                    font = UIFont(name: fontName, size: 23.0) {

                    $0.cell.nameLabel.font = font
                }
        }

        let fontPickingRow = InlinePickerRowFormer<FormInlinePickerCell, UIFont>(instantiateType: .Class) {
            $0.titleLabel.text = "Font"
            $0.titleLabel.textColor = UIColor.privyDarkBlueColor
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.displayLabel.font = .boldSystemFontOfSize(14)
        }.configure {
            $0.pickerItems = fonts.map { font in
                let attributes = [
                    NSFontAttributeName: font
                ]

                let attributed = NSAttributedString(
                    string: font.fontName,
                    attributes: attributes
                )

                return InlinePickerItem(
                    title: font.fontName,
                    displayTitle: attributed,
                    value: font
                )
            }

            let defaults = NSUserDefaults.standardUserDefaults()

            if let fontName = defaults.objectForKey("userFontName") as? String,
                font = UIFont(name: fontName, size: 23.0) {
                $0.selectedRow = fonts.indexOf({ $0.fontName == font.fontName }) ?? 0
            } else {
                $0.selectedRow = 0
            }

            $0.displayEditingColor = UIColor.privyDarkBlueColor
        }.onValueChanged {
            previewRow.cell.fontName = $0.value?.fontName

            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject($0.value?.fontName, forKey: "userFontName")
            defaults.synchronize()
        }

        let stylePickingRow = InlinePickerRowFormer<FormInlinePickerCell, Theme>(instantiateType: .Class) {
            $0.titleLabel.text = "Theme"
            $0.titleLabel.textColor = UIColor.privyDarkBlueColor
            $0.titleLabel.font = .boldSystemFontOfSize(16)
            $0.displayLabel.font = .boldSystemFontOfSize(14)
        }.configure {
            $0.pickerItems = ThemeManager.defaultManager.allThemes.map {
                InlinePickerItem(
                    title: $0.name,
                    displayTitle: nil,
                    value: $0
                )
            }

            $0.selectedRow = ThemeManager.defaultManager.allThemes.indexOf {
                $0 == ThemeManager.defaultManager.defaultTheme
            } ?? 0
        }.onValueChanged {
            ThemeManager.defaultManager.defaultTheme = $0.value!
            previewRow.cell.primaryColor = $0.value?.primaryColor
            previewRow.cell.secondaryColor = $0.value?.secondaryColor
        }

        // Create Headers
        let createHeader: (String -> ViewFormer) = { text in
            return LabelViewFormer<FormLabelHeaderView>()
                .configure {
                    $0.viewHeight = 40
                    $0.text = text
            }
        }

        let previewSection = SectionFormer(
            rowFormer: previewRow
        ).set(headerViewFormer: createHeader("Preview"))

        let fontSection = SectionFormer(
            rowFormer: fontPickingRow, stylePickingRow
        ).set(headerViewFormer: createHeader("Customize Your Card"))

        former.append(sectionFormer: previewSection, fontSection)
            .onCellSelected { [weak self] _ in
                self?.formerInputAccessoryView.update()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func generateFonts() -> [UIFont] {
        return UIFont.familyNames().flatMap {
            UIFont.fontNamesForFamilyName($0).flatMap {
                UIFont(name: $0, size: UIFont.systemFontSize())
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction private func dismiss(button: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction private func logout(button: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .Alert
        )

        let logoutAction = UIAlertAction(
            title: "Logout",
            style: .Destructive) { [unowned self] action in
                self.triggerLogout()
        }

        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: nil
        )

        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }

    private func triggerLogout() {
        // Had to have at least one pyramid of doom.
        RequestManager.sharedManager.logout { success in
            LocalStorage.defaultStorage.saveHistory([HistoryUser]())

            dispatch_async(dispatch_get_main_queue()) {

                LocalStorage.defaultStorage.saveUser(nil) { _ in

                    dispatch_async(dispatch_get_main_queue()) {

                        PrivyUser.currentUser.registrationInformation = nil
                        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            }
        }
    }
}
