//
//  TrackingConfiguration.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03//2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

class TrackingConfiguration: OnboardingPageConfiguration {
    
    init(_ miniVersion:Bool) {
        super.init(title: OnboardingPageConfiguration.adjustDescription(title: UserText.onboardingTrackingTitle,
                                                                        minify:miniVersion),
                   description: OnboardingPageConfiguration.adjustDescription(title:UserText.onboardingTrackingDescription,
                                                                              minify:miniVersion),
                   image: #imageLiteral(resourceName: "OnboardingNoTracking"),
                   background: UIColor.onboardingTrackingBackground)
    }
}
