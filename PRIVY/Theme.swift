//
//  Theme.swift
//  Privy
//
//  Created by Michael MacCallum on 4/17/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

struct Theme {
    let name: String
    let primaryColor: UIColor
    let secondaryColor: UIColor
}

extension Theme: Equatable { }

func == (lhs: Theme, rhs: Theme) -> Bool {
    return lhs.name == rhs.name
        && lhs.primaryColor == rhs.primaryColor
        && lhs.secondaryColor == rhs.secondaryColor
}