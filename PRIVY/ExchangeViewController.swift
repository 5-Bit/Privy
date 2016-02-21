//
//  PRVExchangeViewController.swift
//  PRIVY
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit
import DynamicButton
import NVActivityIndicatorView

class ExchangeViewController: UIViewController {
    @IBOutlet private weak var closeButton: DynamicButton! {
        didSet {
            closeButton.setStyle(DynamicButton.Style.Close, animated: false)

            closeButton.lineWidth           = 2
            closeButton.strokeColor         = UIColor.privyLightBlueColor
            closeButton.highlightStokeColor = UIColor.whiteColor()
            closeButton.backgroundColor     = UIColor.whiteColor()
            closeButton.layer.cornerRadius  = closeButton.bounds.width / 2.0
            closeButton.layer.masksToBounds = true
        }
    }
    
    @IBOutlet private weak var loadingIndicator: NVActivityIndicatorView! {
        didSet {
            loadingIndicator.type = NVActivityIndicatorType.BallClipRotateMultiple
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.size = loadingIndicator.bounds.size
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        loadingIndicator.startAnimation()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        loadingIndicator.stopAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
