//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGHomeViewController.h"
#import "DDGCache.h"
#import <QuartzCore/QuartzCore.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGChooseSourcesViewController.h"
#import "NSArray+ConcurrentIteration.h"
#import "ECSlidingViewController.h"
#import "DDGUnderViewController.h"
#import "DDGSettingsViewController.h"

@interface DDGHomeViewController ()
@end

@implementation DDGHomeViewController

#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {    
    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:queryOrURL];
}

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	DDGSearchController *searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" containerViewController:self];
	searchController.searchHandler = self;
    searchController.state = DDGSearchControllerStateHome;
    self.searchController = searchController;
}

- (void)setContentController:(UIViewController *)contentController {
    if (contentController == _contentController)
        return;
    
    [_contentController willMoveToParentViewController:nil];
    [contentController willMoveToParentViewController:self];
    
    [_contentController.view removeFromSuperview];
    
    CGRect searchbarRect = [self.view convertRect:self.searchController.searchBar.frame fromView:self.searchController.searchBar.superview];
    CGRect frame = self.view.bounds;
    CGRect intersection = CGRectIntersection(frame, searchbarRect);
    frame.origin.y = intersection.origin.y + intersection.size.height;
    frame.size.height = frame.size.height - frame.origin.y;
    
    contentController.view.frame = frame;
    [self.view insertSubview:contentController.view belowSubview:self.searchController.view];
    
    [_contentController removeFromParentViewController];
    [self addChildViewController:contentController];
    
    _contentController = contentController;
}

@end
