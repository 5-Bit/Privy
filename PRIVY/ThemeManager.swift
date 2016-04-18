//
//  ThemeManager.swift
//  Privy
//
//  Created by Michael MacCallum on 4/18/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import UIKit

final class ThemeManager {
    static let defaultManager = ThemeManager()

    private init() {

    }

    var defaultTheme: Theme {
        get {
            let index = NSUserDefaults.standardUserDefaults().integerForKey("defaultTheme")
            return allThemes[index]
        }

        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(
                allThemes.indexOf({ $0 == newValue }) ?? 0,
                forKey: "defaultTheme"
            )
            defaults.synchronize()
        }
    }

    let allThemes = ThemeManager.loadThemes()

    private static func loadThemes() -> [Theme] {
        guard let themes = NSArray(
            contentsOfURL: NSBundle.mainBundle().URLForResource(
                "Themes",
                withExtension: "plist"
            )!
        ) as? [[String: String]] else {
            fatalError()
        }

        return themes.map {
            Theme(
                name: $0["name"]!,
                primaryColor: UIColor(string: $0["primaryColor"]!),
                secondaryColor: UIColor(string: $0["secondaryColor"]!)
            )
        }
    }
}
