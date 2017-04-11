//
//  RealPrivacyConfiguration.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03//2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

class RealPrivacyConfiguration: OnboardingPageConfiguration {
    
    init(_ miniVersion:Bool) {
        super.init(title: UserText.onboardingRealPrivacyTitle,
                   description: OnboardingPageConfiguration.adjustDescription(title: UserText.onboardingRealPrivacyDescription,
                                                                              minify:miniVersion),
                   image: #imageLiteral(resourceName: "OnboardingRealPrivacy"),
                   background: UIColor.onboardingRealPrivacyBackground)
    }
    
}
