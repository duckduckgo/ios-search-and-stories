//
//  UserText.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 24/01/2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import Foundation

public struct UserText {
    
    public static let onboardingRealPrivacyTitle = forKey("onboarding.realprivacy.title")
    public static let onboardingRealPrivacyDescription = forKey( "onboarding.realprivacy.description")
    public static let onboardingContentBlockingTitle = forKey("onboarding.contentblocking.title")
    public static let onboardingContentBlockingDescription = forKey("onboarding.contentblocking.description")
    public static let onboardingTrackingTitle = forKey("onboarding.tracking.title")
    public static let onboardingTrackingDescription = forKey("onboarding.tracking.description")
    public static let onboardingPrivacyRightTitle = forKey("onboarding.privacyright.title")
    public static let onboardingPrivacyRightDescription = forKey("onboarding.privacyright.description")
    
    private static func forKey(_ key: String) -> String {
        let fallback = fallbackStringForKey(key)
        return Bundle.main.localizedString(forKey: key, value: fallback, table: nil)
    }
    
    private static func fallbackStringForKey(_ key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj") else { return nil }
        guard let bundle = Bundle(path: path) else { return nil }
        let string = bundle.localizedString(forKey: key, value: key, table: nil)
        return string
    }
}
