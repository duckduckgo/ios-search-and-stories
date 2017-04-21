//
//  OnboardingPageConfiguration.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03/2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

class OnboardingPageConfiguration {
    
    open let title:String
    open let description:String
    open let image:UIImage
    open let background:UIColor
    
    static func adjustDescription(title:String, minify:Bool) -> String {
        if(minify) {
            var tweakedTitle = title.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: " ") // strip hard-coded newlines
            if let lastSpaceRange = tweakedTitle.range(of: " ", options: .backwards, range: nil, locale: nil) {
                tweakedTitle = tweakedTitle.replacingCharacters(in: lastSpaceRange, with: "\u{2060} \u{2060}")
            }
            return tweakedTitle
        } else {
            return title;
        }
    }
    
    init(title:String, description:String, image:UIImage, background:UIColor) {
        self.title = title
        self.description = description
        self.image = image
        self.background = background
    }
}
