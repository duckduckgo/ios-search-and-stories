//
//  OnboardingDataSource.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03/2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

class OnboardingDataSource: NSObject, UIPageViewControllerDataSource {
    
    private let pages: [UIViewController]
    
    var count: Int {
        return pages.count
    }
    
    init(storyboard: UIStoryboard, mini:Bool = false) {
        let first = OnboardingPageViewController.loadFromStoryboard(storyboard: storyboard,
                                                                    withConfiguartion: RealPrivacyConfiguration(mini))
        let second = OnboardingPageViewController.loadFromStoryboard(storyboard: storyboard, withConfiguartion: ContentBlockingConfiguration(mini))
        let third = OnboardingPageViewController.loadFromStoryboard(storyboard: storyboard, withConfiguartion: TrackingConfiguration(mini))
        let fourth =  OnboardingPageViewController.loadFromStoryboard(storyboard: storyboard, withConfiguartion: PrivacyRightConfiguration(mini))
        fourth.isLastPage = true
        self.pages = [first, second, third, fourth]
        super.init()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let current = pages.index(of: viewController), let previous = previousIndex(current) {
            return pages[previous]
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let current = pages.index(of: viewController), let next = nextIndex(current) {
            return pages[next]
        }
        return nil
    }
    
    func controller(forIndex index: Int) -> UIViewController {
        return pages[index]
    }
    
    func index(of controller: UIViewController) -> Int? {
        return pages.index(of: controller)
    }
    
    func previousIndex(_ index: Int) -> Int? {
        return pages.index(index, offsetBy: -1, limitedBy: 0)
    }
    
    func nextIndex(_ index: Int) -> Int? {
        return pages.index(index, offsetBy: +1, limitedBy: pages.count-1)
    }
    
    func lastIndex() -> Int {
        return pages.count - 1
    }
}
