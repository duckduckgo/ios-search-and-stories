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
            return title.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: " ")
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
