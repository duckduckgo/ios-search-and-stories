//
//  OnboardingMiniCollectionCell.swift
//  DuckDuckGo
//
//  Created by Sean Reilly on 2017.04.12.
//
//

import Foundation
import UIKit

public class OnboardingMiniCollectionViewCell : UICollectionViewCell {
    var onboarder: MiniOnboardingViewController? {
        didSet {
            if let onboarder = self.onboarder {
                onboarder.view.frame = self.contentView.frame
                self.contentView.addSubview(onboarder.view)
            }
        }
    }
    
}


public class OnboardingMiniTableViewCell : UITableViewCell {
    var onboarder: MiniOnboardingViewController? {
        didSet {
            if let onboarder = self.onboarder {
                onboarder.view.frame = self.contentView.frame
                self.contentView.addSubview(onboarder.view)
            }
        }
    }
    
}



