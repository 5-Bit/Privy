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
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var secondLabel: UILabel!
    @IBOutlet private weak var thirdLabel: UILabel!
    @IBOutlet private weak var fourthLabel: UILabel!
    @IBOutlet private weak var qrCodeImageView: UIImageView!

    var fontName: String? {
        didSet {
            if let fontName = fontName {
                nameLabel.font = UIFont(name: fontName, size: nameLabel.font.pointSize)
            }
        }
    }

    var color: UIColor? {
        didSet {
            contentView.backgroundColor = color
            generateQrCode(color)
        }
    }

    private func generateQrCode(color: UIColor?) {
        let operation = QRGeneratorOperation(
            qrString: PrivyUser.currentUser.qrString,
            size: self.qrCodeImageView?.bounds.size ?? CGSize(width: 151, height: 151),
            scale: UIScreen.mainScreen().scale,
            correctionLevel: .Medium,
            backgroundColor: color ?? UIColor.blackColor()) { (image) in
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.qrCodeImageView.image = image
                }
        }

        NSOperationQueue().addOperation(operation)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }    
}