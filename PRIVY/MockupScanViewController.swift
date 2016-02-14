//
//  MockupScanViewController.swift
//  Privy
//
//  Created by Michael MacCallum on 2/9/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

class MockupScanViewController: UIViewController {
    @IBOutlet private weak var imageView: UIImageView!
    private let queue = NSOperationQueue()
    
    var data: [String?]? {
        didSet {
            guard let strings = data else {
                return
            }
            
            let processed = strings.flatMap({ $0 }).reduce("", combine: +)
            
            let op = QRGeneratorOperation(
                qrString: processed,
                size: CGSize(width: 320.0, height: 320.0),
                scale: UIScreen.mainScreen().scale,
                correctionLevel: .High) { image in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.imageView.image = image
                    }
            }
            
            queue.addOperation(op)
        }
    }

    private var blackBarThing = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        blackBarThing.backgroundColor = UIColor.redColor()
        imageView.addSubview(blackBarThing)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        blackBarThing.frame = CGRect(
            x: 0.0,
            y: 0.0,
            width: imageView.bounds.width,
            height: 10.0
        )
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(1.0,
            delay: 0.25,
            options: [.Autoreverse, .Repeat],
            animations: { () -> Void in
                self.blackBarThing.frame = CGRect(
                    x: 0.0,
                    y: self.imageView.bounds.height - self.blackBarThing.bounds.height,
                    width: self.blackBarThing.bounds.width,
                    height: self.blackBarThing.bounds.height
                )
            }, completion: nil)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("doneScanning", sender: self)
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

}
