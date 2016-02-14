//
//  MockupEntryViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/11/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class MockupEntryViewController: UIViewController {
    @IBOutlet private weak var firstNameTextField: UITextField!
    @IBOutlet private weak var lastNameTextField: UITextField!
    @IBOutlet private weak var emailAddressTextField: UITextField!
    @IBOutlet private weak var phoneNumberTextField: UITextField!
    @IBOutlet private weak var twitterHandleTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = NSUserDefaults.standardUserDefaults()
        
        firstNameTextField.text = defaults.objectForKey("first") as? String
        lastNameTextField.text = defaults.objectForKey("last") as? String
        emailAddressTextField.text = defaults.objectForKey("email") as? String
        phoneNumberTextField.text = defaults.objectForKey("phone") as? String
        twitterHandleTextField.text = defaults.objectForKey("twitter") as? String
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let destination = segue.destinationViewController as? MockupScanViewController else {
            return
        }
        
        destination.data = [
            firstNameTextField.text, lastNameTextField.text,
            emailAddressTextField.text, phoneNumberTextField.text,
            twitterHandleTextField.text
        ]
    }
}

extension MockupEntryViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(textField: UITextField) {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setObject(firstNameTextField.text, forKey: "first")
        defaults.setObject(lastNameTextField.text, forKey: "last")
        defaults.setObject(emailAddressTextField.text, forKey: "email")
        defaults.setObject(phoneNumberTextField.text, forKey: "phone")
        defaults.setObject(twitterHandleTextField.text, forKey: "twitter")
        
        defaults.synchronize()
    }
}