//
//  Misc Extensions.swift
//  Privy
//
//  Created by Michael MacCallum on 2/24/16.
//  Copyright © 2016 Michael MacCallum. All rights reserved.
//

import Foundation

private extension NSMutableURLRequest {
    func addValue(value: String, forHTTPHeaderField field: PrivyHttpHeaderField) {
        addValue(value, forHTTPHeaderField: field.rawValue)
    }
}

extension NSURL {
    func urlByAppendingQueryItems(queryItems: [NSURLQueryItem]) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems
        
        return components!.URL!
    }
}
