//
//  OnboardingViewController.swift
//  DuckDuckGo
//
//  Created by Mia Alexiou on 03/03/2017.
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//

import UIKit

let kDDGMiniOnboardingAnimateName = "animate_mini_onboarding"

class MiniOnboardingViewController: UIViewController, UIPageViewControllerDelegate {
    static var performAnimations = true
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint?
    @IBOutlet weak var addToSafariButton: UIButton!
    @IBOutlet weak var bottomBorderHeightConstraint: NSLayoutConstraint?
    
    private weak var pageController: UIPageViewController!
    private var pageFlipTimer: Timer?
    
    private var transitioningToPage: OnboardingPageViewController?
    fileprivate var dataSource: OnboardingDataSource!
    var dismissHandler: (() -> Void)?
    
    public var bottomBorderHidden = false {
        didSet {
            self.loadViewIfNeeded()
            self.bottomBorderHeightConstraint?.constant = self.bottomBorderHidden ? 0 : 10
            self.view.setNeedsLayout()
        }
    }
    
    static func loadFromStoryboard() -> MiniOnboardingViewController {
        let storyboard = UIStoryboard.init(name: "MiniOnboarding", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "MiniOnboardingViewController") as! MiniOnboardingViewController
        controller.dataSource = OnboardingDataSource(storyboard: storyboard, mini:true)
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePageControl()
        self.addToSafariButton?.layer.cornerRadius = 3.0
        self.addToSafariButton?.layer.masksToBounds = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(stopAnimating),
                                               name: NSNotification.Name(rawValue: kDDGMiniOnboardingAnimateName),
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.pageFlipTimer == nil && MiniOnboardingViewController.performAnimations {
            self.pageFlipTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.pageFlipTimer?.invalidate()
        self.pageFlipTimer = nil
    }
    
    func timerFired(timer:Timer) {
        if let pageControl = pageControl {
            var nextPage = pageControl.currentPage + 1
            if nextPage >= pageControl.numberOfPages {
                nextPage = 0
            }
            
            // skip to the next controller...
            let controllers = [dataSource.controller(forIndex: nextPage)]
            pageController.setViewControllers(controllers, direction: .forward, animated: true, completion: nil)
            configureDisplay(forPage: nextPage)
        }
    }
    
    @objc func stopAnimating(timer:Timer) {
        MiniOnboardingViewController.performAnimations = false
        self.pageFlipTimer?.invalidate()
    }
    
    private func configurePageControl() {
        pageControl.numberOfPages = dataSource.count
        pageControl.currentPage = 0
    }
    
    override func viewDidLayoutSubviews() {
        configureDisplayForVerySmallHandsets()
    }
    
    private func configureDisplayForVerySmallHandsets() {
        if view.bounds.height <= 480 && view.bounds.width <= 480 {
            bottomMarginConstraint?.constant = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? UIPageViewController {
            prepare(forPageControllerSegue: controller)
        }
    }
    
    private func prepare(forPageControllerSegue controller: UIPageViewController) {
        pageController = controller
        controller.dataSource = dataSource
        controller.delegate = self
        goToPage(index: 0)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        // the user swiped to a different page, so let's cancel the rotation timer, and fire a notification so that any others do the same
        self.pageFlipTimer?.invalidate()
        self.pageFlipTimer = nil
        MiniOnboardingViewController.performAnimations = false
        
        guard let next = pendingViewControllers.first as? OnboardingPageViewController else { return }
        transitioningToPage = next
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kDDGMiniOnboardingAnimateName), object: nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            guard let previous = previousViewControllers.first as? OnboardingPageViewController else { return }
            guard let index = dataSource.index(of: previous) else { return }
            configureDisplay(forPage: index)
        } else {
            guard let current = transitioningToPage else { return }
            guard let index = dataSource.index(of: current) else { return }
            configureDisplay(forPage: index)
        }
        transitioningToPage = nil
    }
    
    private func configureDisplay(forPage index: Int) {
        pageControl.currentPage = index
        currentPageController().resetImage()
    }
    
    private func shrinkImages(withRatio ratio: CGFloat) {
        let currentImageScale = 1 - (0.2 * (1 - ratio))
        currentPageController().scaleImage(currentImageScale)
        
        let nextImageScale = 1 - (0.2 * ratio)
        transitioningToPage?.scaleImage(nextImageScale)
    }
    
    private func goToPage(index: Int) {
        let controllers = [dataSource.controller(forIndex: index)]
        pageController.setViewControllers(controllers, direction: .forward, animated: true, completion: nil)
        configureDisplay(forPage: index)
    }
    
    @IBAction func onPageSelected(_ sender: UIPageControl) {
        goToPage(index: sender.currentPage)
    }
    
    @IBAction func onDonePressed(_ sender: UIButton) {
      if let dismissHandler = self.dismissHandler {
        dismissHandler()
      }
    }
    
    fileprivate func currentPageController() -> OnboardingPageViewController {
        return dataSource.controller(forIndex: pageControl.currentPage) as! OnboardingPageViewController
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

