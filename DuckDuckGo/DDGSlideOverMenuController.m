//
//  DDGSlideOverMenuController.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import "DDGSlideOverMenuController.h"

NSString * const DDGSlideOverMenuWillAppearNotification = @"DDGSlideOverMenuWillAppearNotification";
NSString * const DDGSlideOverMenuDidAppearNotification = @"DDGSlideOverMenuDidAppearNotification";

@interface DDGSlideOverMenuController ()

@property (nonatomic, assign, readwrite, getter = isAnimating) BOOL animating;
@property (nonatomic, assign, readwrite, getter = isShowingMenu) BOOL showingMenu;

@end

@implementation DDGSlideOverMenuController

#pragma mark - DDGSlideOverMenuController

- (void)hideMenu
{
    [self hideMenu:YES];
}

- (void)hideMenu:(BOOL)animated
{
    if (self.isShowingMenu) {
        [self triggerMenuAppearanceTransition:NO animated:animated];
    }
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
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

- (void)setMenuViewController:(UIViewController *)menuViewController
{
    if (!self.isAnimating) {
        CGRect frame = [self frameForMenuViewController];
        if (_menuViewController) {
            [_menuViewController.view removeFromSuperview];
            [_menuViewController willMoveToParentViewController:nil];
            [_menuViewController removeFromParentViewController];
        }
        _menuViewController = menuViewController;
        if (menuViewController) {
            [self addChildViewController:menuViewController];
            [menuViewController.view setFrame:frame];
            [self.view addSubview:menuViewController.view];
            [menuViewController didMoveToParentViewController:self];
        }
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Attempted to change the menu view controller whilst animating"];
    }
}

- (void)showMenu
{
    [self showMenu:YES];
}

- (void)showMenu:(BOOL)animated
{
    if (!self.isShowingMenu) {
        [self triggerMenuAppearanceTransition:YES animated:animated];
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

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self endAppearanceTransitionOnViewController:self.isShowingMenu ? self.menuViewController : self.contentViewController];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self endAppearanceTransitionOnViewController:self.isShowingMenu ? self.menuViewController : self.contentViewController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self beginAppearanceTransitionOnViewController:self.isShowingMenu ? self.menuViewController : self.contentViewController
                                          appearing:YES
                                           animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self beginAppearanceTransitionOnViewController:self.isShowingMenu ? self.menuViewController : self.contentViewController
                                          appearing:NO
                                           animated:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateLayout];
}

#pragma mark - Private

- (void)beginAppearanceTransitionOnViewController:(UIViewController *)viewController appearing:(BOOL)isAppearing animated:(BOOL)animated
{
    [viewController beginAppearanceTransition:isAppearing animated:animated];
}

- (void)endAppearanceTransitionOnViewController:(UIViewController *)viewController
{
    [viewController endAppearanceTransition];
}

- (CGRect)frameForMenuViewController
{
    return self.isShowingMenu ? [self onScreenFrameForMenuViewController] : [self offScreenFrameForMenuViewController];
}

- (void)notifyObserversAboutMenuAppearanceTransition:(BOOL)complete
{
    NSString *notification = complete ? DDGSlideOverMenuDidAppearNotification : DDGSlideOverMenuWillAppearNotification;
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
}

- (CGRect)offScreenFrameForMenuViewController
{
    CGRect frame = [self.view bounds];
    frame.origin.x -= CGRectGetWidth(frame);
    return frame;
}

- (CGRect)onScreenFrameForMenuViewController
{
    return [self.view bounds];
}

- (void)setup
{
    self.animating = NO;
    self.showingMenu = NO;
}

- (void)setupMenuAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
    self.showingMenu = !self.isShowingMenu;
    [self notifyObserversAboutMenuAppearanceTransition:NO];
    [self beginAppearanceTransitionOnViewController:self.menuViewController appearing:isAppearing animated:animated];
    [self beginAppearanceTransitionOnViewController:self.contentViewController appearing:!isAppearing animated:animated];
}

- (void)tearDownMenuAppearanceTransition
{
    [self endAppearanceTransitionOnViewController:self.menuViewController];
    [self endAppearanceTransitionOnViewController:self.contentViewController];
    [self notifyObserversAboutMenuAppearanceTransition:YES];
}

- (void)triggerMenuAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
    if (self.menuViewController) {
        [self setupMenuAppearanceTransition:isAppearing animated:animated];
        CGRect frame = isAppearing ? [self onScreenFrameForMenuViewController] : [self offScreenFrameForMenuViewController];
        if (animated) {
            self.animating = YES;
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [[self.menuViewController view] setFrame:frame];
                             }
                             completion:^(BOOL finished) {
                                 self.animating = NO;
                                 [self tearDownMenuAppearanceTransition];
                             }];
        } else {
            [[self.menuViewController view] setFrame:frame];
            [self tearDownMenuAppearanceTransition];
        }
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Attempted to animate a nil menu view controller"];
    }
}

- (void)updateLayout
{
    [[self.menuViewController view] setFrame:[self frameForMenuViewController]];
}

@end
