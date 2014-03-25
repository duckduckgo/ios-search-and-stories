//
//  DDGSlideOverMenuController.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import "DDGSlideOverMenuController.h"

@interface DDGSlideOverMenuController ()

@property (nonatomic, assign, readwrite, getter = isAnimating) BOOL animating;

@end

@implementation DDGSlideOverMenuController

#pragma mark -

- (void)setContentViewController:(UIViewController *)contentViewController
{
    if (!self.isAnimating) {
        if (_contentViewController) {
            [_contentViewController.view removeFromSuperview];
            [_contentViewController willMoveToParentViewController:nil];
            [_contentViewController removeFromParentViewController];
        }
        _contentViewController = contentViewController;
        if (contentViewController) {
            [self addChildViewController:contentViewController];
            [contentViewController.view setFrame:[self.view bounds]];
            if (self.menuViewController) {
                [self.view insertSubview:contentViewController.view belowSubview:[self.menuViewController view]];
            } else {
                [self.view addSubview:contentViewController.view];
            }
            [contentViewController didMoveToParentViewController:self];
        }
    }
}

- (void)setMenuViewController:(UIViewController *)menuViewController
{
    if (!self.isAnimating) {
        if (_menuViewController) {
            [_menuViewController.view removeFromSuperview];
            [_menuViewController willMoveToParentViewController:nil];
            [_menuViewController removeFromParentViewController];
        }
        _menuViewController = menuViewController;
        if (menuViewController) {
            // Layout menu controller
        }
    }
}

#pragma mark - UIViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle
{
    self = [super initWithNibName:name bundle:bundle];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Private

- (void)setup
{
    self.animating = NO;
}

@end
