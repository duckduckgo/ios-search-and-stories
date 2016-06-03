//
//  DDGTabViewController.m
//  SyncSpace
//
//  Created by Johnnie Walker on 14/12/2011.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGTabViewController.h"
#import "UIViewController+DDGSearchController.h"

@interface DDGTabViewController () <UITabBarControllerDelegate>
@property (nonatomic, strong) IBOutlet DDGSegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet UIView *controlView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, weak, readwrite) UIViewController *currentViewController;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* segmentWidthConstraint;
@property (nonatomic, strong) UITabBarController* tabController;
@end


@implementation DDGTabViewController


-(id)init
{
    self = [super initWithNibName:@"DDGTabViewController" bundle:nil];
    return self;
}

-(void)viewDidLoad
{
  [super viewDidLoad];
    self.controlView.backgroundColor = [UIColor duckSearchBarBackground];
    for (UIViewController *viewController in self.viewControllers) {
        [self.segmentedControl addSegment:[[UIBarButtonItem alloc] initWithTitle:viewController.title
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:nil action:nil]];
    }

    self.tabController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    self.tabController.delegate = self;
    [self addChildViewController:self.tabController];
    self.tabController.view.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    self.contentView.backgroundColor = [UIColor duckSearchBarBackground]; // hack to workaround app switcher flickering issue
    [self.contentView addSubview:self.tabController.view];
    [self.tabController didMoveToParentViewController:self];
    self.tabController.tabBar.hidden = TRUE;
    self.tabController.viewControllers = self.viewControllers;
    
    [self.segmentedControl addTarget:self action:@selector(segmentWasSelected:) forControlEvents:UIControlEventValueChanged];
}

- (UIView*)dimmableContentView
{
    return self.contentView;
}

-(void)duckGoToTopLevel
{
    [self.currentViewController duckGoToTopLevel];
}

- (CGFloat)duckPopoverIntrusionAdjustment {
    return 8.0f;
}

-(void)alignSegmentBarConstraints
{
    if(self.segmentAlignmentView) {
        self.segmentWidthConstraint.constant = self.segmentAlignmentView.frame.size.width - 16;
    } else {
        self.segmentWidthConstraint.constant = self.controlView.frame.size.width-16;
    }
    [self.view setNeedsUpdateConstraints];
}


-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self alignSegmentBarConstraints];
}

- (IBAction)segmentWasSelected:(id)sender {
    if (sender != self.segmentedControl)
        return;
    [self setCurrentViewControllerIndex:self.segmentedControl.selectedSegmentIndex];
}

-(UIViewController*)currentViewController {
    return self.tabController.selectedViewController;
}

- (NSInteger)currentViewControllerIndex {
    return self.tabController.selectedIndex;
}

- (void)setCurrentViewControllerIndex:(NSInteger)newViewControllerIndex {
    NSAssert1(newViewControllerIndex < [self.viewControllers count], @"Attempt to select a view controller beyond range of tabViewControllers %ld", (long)newViewControllerIndex);    
    self.tabController.selectedIndex = newViewControllerIndex;
    [self.segmentedControl setSelectedSegmentIndex:newViewControllerIndex];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self alignSegmentBarConstraints];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - UITabBarControllerDelegate





#pragma mark - UIViewController

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.segmentedControl = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (nil != self.currentViewController && nil == self.currentViewController.view.superview) {
        NSInteger index = self.currentViewControllerIndex;
        self.currentViewController = nil;
        [self setCurrentViewControllerIndex:index];        
    }
    [self.currentViewController viewWillAppear:animated];
        
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.currentViewController viewDidAppear:animated];
}

@end
