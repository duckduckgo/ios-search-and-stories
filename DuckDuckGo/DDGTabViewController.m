//
//  DDGTabViewController.m
//  SyncSpace
//
//  Created by Johnnie Walker on 14/12/2011.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGTabViewController.h"
#import "UIViewController+DDGSearchController.h"

@interface DDGTabViewController ()
@property (nonatomic, strong) IBOutlet DDGSegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet UIView *controlView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, weak, readwrite) UIViewController *currentViewController;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* segmentWidthConstraint;
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
    self.view.backgroundColor = [UIColor blueColor];
    
    [self.segmentedControl addTarget:self action:@selector(segmentWasSelected:) forControlEvents:UIControlEventValueChanged];
    
}


-(void)duckGoToTopLevel
{
    [self.currentViewController duckGoToTopLevel];
}

-(void)viewDidLayoutSubviews
{
  if(self.segmentAlignmentView) {
    self.segmentWidthConstraint.constant = self.segmentAlignmentView.frame.size.width - 18;
  } else {
    self.segmentWidthConstraint.constant = self.controlView.frame.size.width-16;
  }
}

- (IBAction)segmentWasSelected:(id)sender {
    if (sender != self.segmentedControl)
        return;
    [self setCurrentViewControllerIndex:self.segmentedControl.selectedSegmentIndex];
}

- (NSInteger)currentViewControllerIndex {
    return [self.viewControllers indexOfObject:self.currentViewController];
}

- (void)setCurrentViewControllerIndex:(NSInteger)newViewControllerIndex {
    NSAssert1(newViewControllerIndex < [self.viewControllers count], @"Attempt to select a view controller beyond range of tabViewControllers %ld", (long)newViewControllerIndex);
    
    UIViewController *nextViewController = [self.viewControllers objectAtIndex:newViewControllerIndex];

    [self willChangeValueForKey:@"currentViewController"];
    [self willChangeValueForKey:@"currentViewControllerIndex"];    
    CGRect contentRect = self.contentView.frame;
    contentRect.origin.x = 0;
    contentRect.origin.y = 0;
    if (nextViewController != self.currentViewController) {
        [self addChildViewController:nextViewController];
        [nextViewController.view setFrame:contentRect];
        if (self.currentViewController.view) {
            [self.contentView insertSubview:nextViewController.view belowSubview:self.currentViewController.view];
        } else {
            [self.contentView insertSubview:nextViewController.view belowSubview:self.controlView];
        }
        [nextViewController didMoveToParentViewController:self];
        
        [self.currentViewController willMoveToParentViewController:nil];
        [self.currentViewController.view removeFromSuperview];
        [self.currentViewController removeFromParentViewController];
        self.currentViewController = nil;
        self.currentViewController = nextViewController;
    }
        
    [self didChangeValueForKey:@"currentViewController"];    
    [self didChangeValueForKey:@"currentViewControllerIndex"];        
    
    [self.segmentedControl setSelectedSegmentIndex:newViewControllerIndex];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return YES;
    }
        
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

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
        
}

@end
