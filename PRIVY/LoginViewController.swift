//
//  LoginViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/23/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import LocalAuthentication

private enum ViewState: String {
    case Login, Registration
}

class LoginViewController: UIViewController {
    @IBOutlet private weak var confirmationButton: UIButton!
    @IBOutlet private weak var stateSwitcherButton: UIButton!

    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!

    @IBOutlet private weak var bottomSpacingPin: NSLayoutConstraint!

    private var activityIndicator: UIActivityIndicatorView!

    private var viewState = ViewState.Login {
        didSet {
            configForViewState()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        confirmationButton.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.frame = CGRect(
            x: confirmationButton.bounds.width - confirmationButton.bounds.height,
            y: 0.0,
            width: confirmationButton.bounds.height,
            height: confirmationButton.bounds.height
        )

        confirmationButton.addSubview(activityIndicator)

        let vertical = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|-[activityIndicator]-|",
            options: [],
            metrics: nil,
            views: ["activityIndicator": activityIndicator]
        )

        let horizontal = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|-[activityIndicator(40)]|",
            options: [],
            metrics: nil,
            views: ["activityIndicator": activityIndicator]
        )

        confirmationButton.addConstraints(vertical + horizontal)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        NSNotificationCenter.defaultCenter().addObserverForName(
            UIKeyboardWillChangeFrameNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: keyboardFrameWillChange
        )

        guard !view.isFirstResponder() else {
            return
        }
        
        if emailTextField.text.isNilOrEmpty {
            emailTextField.becomeFirstResponder()
        } else if passwordTextField.text.isNilOrEmpty {
            passwordTextField.becomeFirstResponder()
        } else if confirmPasswordTextField.text.isNilOrEmpty && viewState == .Registration {
            confirmPasswordTextField.becomeFirstResponder()
        }
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
            let enabled = !emailTextField.text.isNilOrEmpty && !passwordTextField.text.isNilOrEmpty
            confirmationButton.enabled = enabled
            confirmationButton.alpha = enabled ? 1.0 : 0.8
        case .Registration:
            stateSwitcherButton.setTitle("Log In", forState: .Normal)
            confirmationButton.setTitle("Create an Account", forState: .Normal)
            confirmPasswordTextField.hidden = false
            passwordTextField.returnKeyType = .Next
            let enabled = !emailTextField.text.isNilOrEmpty && !passwordTextField.text.isNilOrEmpty && !confirmPasswordTextField.text.isNilOrEmpty && confirmPasswordTextField.text == passwordTextField.text
            confirmationButton.enabled = enabled
            confirmationButton.alpha = enabled ? 1.0 : 0.8            
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
        
        let credential = LoginCredential(email: emailTextField.text!, password: passwordTextField.text!)
        
        let function: (LoginCredential, LoginCompletion) -> Void
        if viewState == .Login {
            function = RequestManager.sharedManager.attemptLoginWithCredentials
        } else {
            function = RequestManager.sharedManager.attemptRegistrationWithCredentials
        }

        confirmationButton.enabled = false
        activityIndicator.startAnimating()
        view.endEditing(true)
        passwordTextField.enabled = false
        confirmPasswordTextField.enabled = false

        function(credential) { response, error in
            switch error {
            case .Ok:
                PrivyUser.currentUser.registrationInformation = response
                let defaults = NSUserDefaults.standardUserDefaults()

                if let currentUser = LocalStorage.defaultStorage.attemptLoginWithCredential(credential) {
                    PrivyUser.currentUser.userInfo = currentUser.userInfo
                    self.navigationController?.popToRootViewControllerAnimated(true)
                    defaults.setObject(currentUser.registrationInformation!.email!, forKey: "current")
                    defaults.synchronize()
                } else {
                    LocalStorage.defaultStorage.saveUser(PrivyUser.currentUser) { _ in
                        defaults.setObject(PrivyUser.currentUser.registrationInformation!.email!, forKey: "current")
                        defaults.synchronize()
                        self.navigationController?.popToRootViewControllerAnimated(true)
                    }
                }
            case .ServerError(let message):
                self.showErrorAlert(message)
                self.resetLoadingUI()
            case .NoResponse:
                self.showErrorAlert("No response from server.")
                self.resetLoadingUI()
            case .UnknownError:
                self.showErrorAlert("An unknown error occurred.")
                self.resetLoadingUI()
            }
        }
    }
    
    private func resetLoadingUI() {
        confirmationButton.enabled = true
        activityIndicator.stopAnimating()
        passwordTextField.enabled = true
        confirmPasswordTextField.enabled = true
    }

    private func showErrorAlert(error: String) {
        let alertController = UIAlertController(
            title: viewState.rawValue + " Error",
            message: error,
            preferredStyle: .Alert
        )

        let dismissAction = UIAlertAction(
            title: "Dismiss",
            style: .Cancel,
            handler: nil
        )
        
        alertController.addAction(dismissAction)
        presentViewController(alertController, animated: true, completion: nil)
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
        let alertController = UIAlertController(
            title: "Forgot Password?",
            message: "A password reset will be emailed to the address given below.",
            preferredStyle: UIAlertControllerStyle.Alert
        )

        let confirmAction = UIAlertAction(
            title: "Confirm",
            style: .Destructive) { action in
                RequestManager.sharedManager.requestPasswordReset(alertController.textFields!.first!.text!) { (success) in
                    print(success)
                }
        }
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: nil
        )
        
        alertController.addTextFieldWithConfigurationHandler { [unowned self] textField in
            textField.keyboardType = .EmailAddress
            textField.text = self.emailTextField.text
            textField.clearButtonMode = .Always

            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                confirmAction.enabled = textField.text != ""
            }
        }

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        presentViewController(alertController, animated: true, completion: nil)
    }

    func authenticateUser() {
        // Get the local authentication context.
        let context = LAContext()

        // Declare a NSError variable.
        var error: NSError?

        // Set the reason string that will appear on the authentication alert.
        let reasonString = "Authentication is needed to access your notes."

        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            context .evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: NSError?) -> Void in

                if success {

                }
                else{
                    // If authentication failed then show a message to the console with a short description.
                    // In case that the error is a user fallback, then show the password alert view.
//                    println(evalPolicyError?.localizedDescription)

                    switch evalPolicyError!.code {

                    case LAError.SystemCancel.rawValue:
                        print("Authentication was cancelled by the system")

                    case LAError.UserCancel.rawValue:
                        print("Authentication was cancelled by the user")

                    case LAError.UserFallback.rawValue:
                        print("User selected to enter custom password")
//                        self.showPasswordAlert()

                    default:
                        print("Authentication failed")
//                        self.showPasswordAlert()
                    }
                }

            })
        }
        else{
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{

            case LAError.TouchIDNotEnrolled.rawValue:
                print("TouchID is not enrolled")

            case LAError.PasscodeNotSet.rawValue:
                print("A passcode has not been set")

            default:
                // The LAError.TouchIDNotAvailable case.
                print("TouchID not available")
            }

            // Optionally the error description can be displayed on the console.
            print(error?.localizedDescription)
            
            // Show the custom alert view to allow users to enter the password.
//            self.showPasswordAlert()
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    @IBAction private func textFieldDidChangeEditing(textField: UITextField) {
        
        if viewState == .Login {
            let enabled = !emailTextField.text.isNilOrEmpty
                && !passwordTextField.text.isNilOrEmpty
                && passwordTextField.text!.characters.count >= 8

            confirmationButton.enabled = enabled
            confirmationButton.alpha = enabled ? 1.0 : 0.8

            passwordTextField.layer.borderColor = UIColor.clearColor().CGColor
            confirmPasswordTextField.layer.borderColor = UIColor.clearColor().CGColor
        } else {
            if passwordTextField.text.isNilOrEmpty != confirmPasswordTextField.text.isNilOrEmpty {
                passwordTextField.layer.borderColor = UIColor.clearColor().CGColor
                confirmPasswordTextField.layer.borderColor = UIColor.clearColor().CGColor
                confirmationButton.enabled = false
                confirmationButton.alpha = 0.8
            } else {
                let enabled = passwordTextField.text == confirmPasswordTextField.text
                    && passwordTextField.text!.characters.count >= 8
                let borderColor = enabled ? UIColor.clearColor().CGColor : UIColor.redColor().CGColor
                
                confirmationButton.enabled = enabled
                confirmationButton.alpha = enabled ? 1.0 : 0.8
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














