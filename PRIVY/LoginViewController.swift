//
//  LoginViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

private enum ViewState {
    case Login, Registration
}

class LoginViewController: UIViewController {
    @IBOutlet private weak var confirmationButton: UIButton!
    @IBOutlet private weak var stateSwitcherButton: UIButton!

    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!

    @IBOutlet private weak var bottomSpacingPin: NSLayoutConstraint!
    
    private var viewState = ViewState.Login {
        didSet {
            configForViewState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserverForName(
            UIKeyboardWillChangeFrameNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: keyboardFrameWillChange
        )
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIKeyboardWillChangeFrameNotification,
            object: nil
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    private func keyboardFrameWillChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? UInt,
            animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval,
            keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() else {
                return
        }

        bottomSpacingPin.constant = keyboardFrame.origin.y == view.bounds.height ? 0.0 : keyboardFrame.height
        
        UIView.animateWithDuration(
            animationDuration,
            delay: 0.0,
            options: UIViewAnimationOptions.BeginFromCurrentState.union(UIViewAnimationOptions(rawValue: animationCurve)),
            animations: { 
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    private func configForViewState() {
        switch viewState {
        case .Login:
            stateSwitcherButton.setTitle("Create an Account", forState: .Normal)
            confirmationButton.setTitle("Log In", forState: .Normal)
            confirmPasswordTextField.hidden = true
            passwordTextField.returnKeyType = .Done
        case .Registration:
            stateSwitcherButton.setTitle("Log In", forState: .Normal)
            confirmationButton.setTitle("Create an Account", forState: .Normal)
            confirmPasswordTextField.hidden = false
            passwordTextField.returnKeyType = .Next
        }

        if confirmPasswordTextField.isFirstResponder() {
            confirmPasswordTextField.resignFirstResponder()
        } else {
            UIView.animateWithDuration(0.15, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @IBAction private func confirmationButtonTapped(button: UIButton!) {
        guard confirmationButton.enabled else {
            return
        }
        
        
    }
    
    @IBAction private func switchingButtonTapped(button: UIButton!) {
        viewState = viewState == .Login ? .Registration : .Login
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction private func forgotPasswordButtonTapped(button: UIButton!) {
        
    }
}

extension LoginViewController: UITextFieldDelegate {
    @IBAction private func textFieldDidChangeEditing(textField: UITextField) {
        
        if viewState == .Login {
            confirmationButton.enabled = !emailTextField.text.isNilOrEmpty
                && !passwordTextField.text.isNilOrEmpty

            passwordTextField.layer.borderColor = UIColor.clearColor().CGColor
            confirmPasswordTextField.layer.borderColor = UIColor.clearColor().CGColor
        } else {
            confirmationButton.enabled = !emailTextField.text.isNilOrEmpty
                && !passwordTextField.text.isNilOrEmpty
                && !confirmPasswordTextField.text.isNilOrEmpty

            if passwordTextField.text.isNilOrEmpty != confirmPasswordTextField.text.isNilOrEmpty {
                passwordTextField.layer.borderColor = UIColor.clearColor().CGColor
                confirmPasswordTextField.layer.borderColor = UIColor.clearColor().CGColor                
            } else {
                let borderColor = passwordTextField.text == confirmPasswordTextField.text
                    ? UIColor.clearColor().CGColor : UIColor.redColor().CGColor
                
                passwordTextField.layer.borderColor = borderColor
                confirmPasswordTextField.layer.borderColor = borderColor
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField === passwordTextField {
            if viewState == .Login {
                confirmationButtonTapped(nil)
            } else {
                confirmPasswordTextField.becomeFirstResponder()
            }
        } else {
            confirmationButtonTapped(nil)
        }
        
        return true
    }
}














