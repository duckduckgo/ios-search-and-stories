//
//  UIColorExtension.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 13/02/2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

extension UIColor {
    
    public static var onboardingRealPrivacyBackground: UIColor {
        return lightOliveGreen
    }
    
    public static var onboardingContentBlockingBackground: UIColor {
        return amethyst
    }
    
    public static var onboardingTrackingBackground: UIColor {
        return fadedOrange
    }
    
    public static var onboardingPrivacyRightBackground: UIColor {
        return softBlue
    }
        
    private static var fadedOrange: UIColor {
        return UIColor(red: 245.0 / 255.0, green: 139.0 / 255.0, blue: 107.0 / 255.0, alpha: 1.0)
    }
    
    private static var lightOliveGreen: UIColor {
        return UIColor(red: 147.0 / 255.0, green: 192.0 / 255.0, blue: 77.0 / 255.0, alpha: 1.0)
    }
    
    private static var amethyst: UIColor {
        return UIColor(red: 156.0 / 255.0, green: 108.0 / 255.0, blue: 211.0 / 255.0, alpha: 1.0)
    }
    
    private static var softBlue: UIColor {
        return UIColor(red: 106.0 / 255.0, green: 187.0 / 255.0, blue: 224.0 / 255.0, alpha: 1.0)
    }
}
