//
//  DynamicHeightCell.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 11/7/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit
import Former

final class PreviewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    @IBOutlet private weak var qrCodeImageView: UIImageView!

    var fontName: String? {
        didSet {
            if let fontName = fontName {
                nameLabel.font = UIFont(name: fontName, size: nameLabel.font.pointSize)
            }
        }
    }

    var primaryColor: UIColor? {
        didSet {
            guard let color = primaryColor else {
                return
            }

            let newColor = UIColor(CGColor: color.CGColor)

            nameLabel.textColor = newColor
            secondLabel.textColor = newColor
            thirdLabel.textColor = newColor
            fourthLabel.textColor = newColor
        }
    }

    var secondaryColor: UIColor? {
        didSet {
            contentView.backgroundColor = secondaryColor
            generateQrCode(secondaryColor)
        }
    }

    let queue = NSOperationQueue()

    private func generateQrCode(color: UIColor?) {
        let operation = QRGeneratorOperation(
            qrString: PrivyUser.currentUser.qrString,
            size: CGSize(width: 120.0, height: 120.0),
            scale: UIScreen.mainScreen().scale,
            correctionLevel: .Medium,
            backgroundColor: color ?? UIColor.blackColor()) { (image) in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.qrCodeImageView.image = image
                    print("done------------------------------")
                    print(image)
                    print(self?.qrCodeImageView)
                }
        }

        queue.addOperation(operation)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }    
}