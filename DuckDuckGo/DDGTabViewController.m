//
//  DDGTabViewController.m
//  SyncSpace
//
//  Created by Johnnie Walker on 14/12/2011.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGTabViewController.h"

@interface DDGTabViewController ()
@property (nonatomic, strong, readwrite) DDGSegmentedControl *segmentedControl;
@property (nonatomic, copy, readwrite) NSArray *viewControllers;
@property (nonatomic, weak, readwrite) UIViewController *currentViewController;
@property (nonatomic, strong) UIView *toolbarDropShadowView;
- (CGRect)_viewControllerFrameForControlViewPosition:(DDGTabViewControllerControlViewPosition)toolbarPosition;
@end

@implementation DDGTabViewController

- (id)initWithViewControllers:(NSArray *)viewControllers
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.viewControllers = viewControllers;
    }
    return self;
}

#pragma mark - View lifecycle


- (CGRect)_viewControllerFrameForControlViewPosition:(DDGTabViewControllerControlViewPosition)controlViewPosition {
    CGRect controlViewFrame = [self.controlView frame];
    CGRect viewControllerFrame;
    CGRect viewBounds = [self.view bounds]; 
    
    switch (controlViewPosition) {
        case DDGTabViewControllerControlViewPositionBottom:
            viewControllerFrame = CGRectMake(viewBounds.origin.x, 
                                             viewBounds.origin.y, 
                                             viewBounds.size.width, 
                                             viewBounds.size.height - controlViewFrame.size.height);
            [self.view addSubview:self.controlView];
            break;
        case DDGTabViewControllerControlViewPositionTop:
            viewControllerFrame = CGRectMake(viewBounds.origin.x, 
                                             viewBounds.origin.y + controlViewFrame.size.height, 
                                             viewBounds.size.width, 
                                             viewBounds.size.height - controlViewFrame.size.height);            
            [self.view addSubview:self.controlView];
            break;
            
        case DDGTabViewControllerControlViewPositionNone:
        default:
            viewControllerFrame = viewBounds;
            [self.controlView removeFromSuperview];            
            break;
    }    
    
    return viewControllerFrame;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    DDGTabViewControllerControlViewPosition position = self.controlViewPosition;
    
    CGRect toolbarFrame = [self.controlView frame];
    CGRect viewControllerFrame = [self _viewControllerFrameForControlViewPosition:position];
    CGRect viewBounds = [self.view bounds];
    
    switch (position) {
        case DDGTabViewControllerControlViewPositionBottom:
            toolbarFrame = CGRectMake(viewBounds.origin.x,
                                      viewBounds.origin.y + viewBounds.size.height - toolbarFrame.size.height,
                                      viewBounds.size.width,
                                      toolbarFrame.size.height);
            [self.view addSubview:self.controlView];
            break;
        case DDGTabViewControllerControlViewPositionTop:
            toolbarFrame = CGRectMake(viewBounds.origin.x,
                                      viewBounds.origin.y,
                                      viewBounds.size.width,
                                      toolbarFrame.size.height);
            [self.view addSubview:self.controlView];
            break;
            
        case DDGTabViewControllerControlViewPositionNone:
        default:
            [self.controlView removeFromSuperview];
            break;
    }
    
    [self.controlView setFrame:toolbarFrame];
    [self.currentViewController.view setFrame:viewControllerFrame];
//
//    [UIView animateWithDuration:0
//                     animations:^{
//                         [self.controlView setFrame:toolbarFrame];
//                         [self.currentViewController.view setFrame:viewControllerFrame];
//                     }
//     ];
}

- (DDGSegmentedControl*)segmentedControl {
    if (nil == _segmentedControl) {        
        DDGSegmentedControl *segmentedControl = [[DDGSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 29)];
        for (UIViewController *viewController in _viewControllers) {
            [segmentedControl addSegment:[[UIBarButtonItem alloc] initWithTitle:viewController.title
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:nil action:nil]];
        }
        segmentedControl.backgroundColor = [UIColor duckSegmentBarBackground];
        segmentedControl.tintColor = [UIColor duckSegmentBarForeground];
        [segmentedControl addTarget:self action:@selector(segmentWasSelected:) forControlEvents:UIControlEventValueChanged];
        
        self.segmentedControl = segmentedControl;
    }
    
    return _segmentedControl;
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

    if (nextViewController != self.currentViewController) {
        [self addChildViewController:nextViewController];    
        [nextViewController.view setFrame:[self _viewControllerFrameForControlViewPosition:self.controlViewPosition]];
        if (self.currentViewController.view) 
            [self.view insertSubview:nextViewController.view belowSubview:self.currentViewController.view]; 
        else
            [self.view insertSubview:nextViewController.view belowSubview:self.controlView];
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
    
    if (nil != self.controlView && nil == self.controlView.superview)
        [self setControlViewPosition:_controlViewPosition];        

    if (nil != self.currentViewController && nil == self.currentViewController.view.superview) {
        NSInteger index = self.currentViewControllerIndex;
        self.currentViewController = nil;
        [self setCurrentViewControllerIndex:index];        
    }
        
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

@end
