//
//  SettingsViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 3/30/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    lazy var fonts: [UIFont] = self.generateFonts()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        RequestManager.sharedManager.logout { success in
            LocalStorage.defaultStorage.saveHistory([HistoryUser]())
            dispatch_async(dispatch_get_main_queue()) {
                LocalStorage.defaultStorage.saveUser(nil, completion: { (error) in
                    dispatch_async(dispatch_get_main_queue()) {
                        PrivyUser.currentUser.registrationInformation = nil

                        self.presentingViewController?.dismissViewControllerAnimated(true, completion: {

                        })
                    }
                })
            }
        }
    }
}
