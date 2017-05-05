//
//  PrivacyRightConfiguration.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03//2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

class PrivacyRightConfiguration: OnboardingPageConfiguration {

    init(_ miniVersion:Bool) {
        super.init(title: OnboardingPageConfiguration.adjustDescription(title: UserText.onboardingPrivacyRightTitle,
                                                                        minify:miniVersion),
                   description: OnboardingPageConfiguration.adjustDescription(title: UserText.onboardingPrivacyRightDescription,
                                                                              minify: miniVersion),
                   image: #imageLiteral(resourceName: "OnboardingPrivacyRight"),
                   background: UIColor.onboardingPrivacyRightBackground)
    }

}
