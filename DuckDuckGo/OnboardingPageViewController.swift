//
//  OnboardingPageViewController.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03/2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

class OnboardingPageViewController: UIViewController {
    
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var pageDescription: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var descriptionContainerHeightConstraint: NSLayoutConstraint?
    
    var descriptionLineHeight: CGFloat = 0
    
    var configuration: OnboardingPageConfiguration!
    var isLastPage = false
    
    var preferredBackgroundColor: UIColor {
        return configuration.background
    }
    
    static func loadFromStoryboard(storyboard: UIStoryboard, withConfiguartion configuration: OnboardingPageConfiguration) -> OnboardingPageViewController {
        let controller = storyboard.instantiateViewController(withIdentifier: "OnboardingPageViewController") as! OnboardingPageViewController
        controller.configuration = configuration
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }
    
    private func configureViews() {
        pageTitle.text = configuration.title
        image.image = configuration.image
        pageDescription.text = configuration.description
        pageDescription.adjustPlainTextLineHeight(descriptionLineHeight)
    }
    
    public func scaleImage(_ scale: CGFloat) {
        image.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    public func resetImage() {
        image.transform = CGAffineTransform(scaleX: 1, y: 1)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // if we have a height constraint for the description text's superview,
        // calculate the natural height of the description text and use it to resize
        // the container, assuming the description text is the bottom item in the container
        if let descContainerHeightC = self.descriptionContainerHeightConstraint, let descLabel = self.pageDescription, let container = descLabel.superview {
            let size = descLabel.sizeThatFits(container.frame.size)
            descContainerHeightC.constant = descLabel.frame.origin.y + size.height
            self.view.setNeedsUpdateConstraints()
        }
    }
}
