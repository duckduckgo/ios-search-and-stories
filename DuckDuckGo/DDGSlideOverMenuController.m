//
//  DDGSlideOverMenuController.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import "DDGHorizontalPanGestureRecognizer.h"
#import "DDGSlideOverMenuController.h"
#import "UIImage+SlideOverMenu.h"
#import "UIView+SlideOverMenu.h"

NSString * const DDGSlideOverMenuWillAppearNotification = @"DDGSlideOverMenuWillAppearNotification";
NSString * const DDGSlideOverMenuDidAppearNotification = @"DDGSlideOverMenuDidAppearNotification";

@interface DDGSlideOverMenuController ()

@property (nonatomic, assign, readwrite, getter = isAnimating) BOOL animating;
@property (nonatomic, strong) UIImageView *blurContainerView;
@property (nonatomic, strong, readwrite) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign, readwrite, getter = isShowingMenu) BOOL showingMenu;
@property (nonatomic, weak, readonly) UIWindow *window;

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
    if ([contentViewController isEqual:self.contentViewController]) {
        return;
    }
    if (_contentViewController) {
        [_contentViewController.view removeFromSuperview];
        [_contentViewController willMoveToParentViewController:nil];
        [_contentViewController removeFromParentViewController];
        [_contentViewController.view removeGestureRecognizer:self.panGesture];
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
        if (self.isShowingMenu) {
            [self updateBlurContainerContent];
        }
        [contentViewController.view addGestureRecognizer:self.panGesture];
    }
    [self reorderViewStack];
}

- (void)setMenuViewController:(UIViewController *)menuViewController
{
    if (!self.isAnimating) {
        if ([menuViewController isEqual:self.menuViewController]) {
            return;
        }
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
        [self reorderViewStack];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupBlurContainer];
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

- (CGRect)frameForBlurContainer
{
    return self.isShowingMenu ? [self onScreenFrameForBlurContainer] : [self offScreenFrameForBlurContainer];
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

- (CGRect)offScreenFrameForBlurContainer
{
    CGRect frame = [self.view bounds];
    frame.size.width = 0.0f;
    return frame;
}

- (CGRect)offScreenFrameForMenuViewController
{
    CGRect frame = [self.view bounds];
    frame.origin.x -= CGRectGetWidth(frame);
    return frame;
}

- (CGRect)onScreenFrameForBlurContainer
{
    return [self.view bounds];
}

- (CGRect)onScreenFrameForMenuViewController
{
    return [self.view bounds];
}

- (void)reorderViewStack
{
    if (self.contentViewController) {
        [self.view sendSubviewToBack:[self.contentViewController view]];
    }
    if (self.menuViewController) {
        [self.view bringSubviewToFront:[self.menuViewController view]];
    }
}

- (void)setup
{
    self.animating = NO;
    self.panGesture = [[DDGHorizontalPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateMenuPositionWhilstPanning:)];
    self.showingMenu = NO;
}

- (void)setupBlurContainer
{
    CGRect frame = [self onScreenFrameForMenuViewController];
    frame.size.width = 0.0f;
    UIImageView *blurContainerView = [[UIImageView alloc] initWithFrame:frame];
    blurContainerView.contentMode = UIViewContentModeTopLeft;
    blurContainerView.clipsToBounds = YES;
    [self.view addSubview:blurContainerView];
    self.blurContainerView = blurContainerView;
}

- (void)setupMenuAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated
{
    self.showingMenu = !self.isShowingMenu;
    if (isAppearing) {
        [self updateBlurContainerContent];
    }
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
        CGFloat alpha = isAppearing ? 0.0f : 1.0f;
        CGRect blurContainerFrame = isAppearing ? [self onScreenFrameForBlurContainer] : [self offScreenFrameForBlurContainer];
        CGRect menuViewFrame = isAppearing ? [self onScreenFrameForMenuViewController] : [self offScreenFrameForMenuViewController];
        if (animated) {
            self.animating = YES;
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [self.blurContainerView setFrame:blurContainerFrame];
                                 [[self.menuViewController view] setFrame:menuViewFrame];
                                 [self.window setAlpha:alpha];
                             }
                             completion:^(BOOL finished) {
                                 self.animating = NO;
                                 [self tearDownMenuAppearanceTransition];
                             }];
        } else {
            [self.blurContainerView setFrame:blurContainerFrame];
            [[self.menuViewController view] setFrame:menuViewFrame];
            [self.window setAlpha:alpha];
            [self tearDownMenuAppearanceTransition];
        }
    } else {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Attempted to animate a nil menu view controller"];
    }
}

- (void)updateBlurContainerContent
{
    UIImage *snapshotImage = [[self.contentViewController view] snapshotImageAfterScreenUpdates:self.isShowingMenu];
    UIImage *blurredSnapshotImage = [snapshotImage imageWithBlurRadius:12.0f
                                                             tintColor:[UIColor colorWithWhite:0.95f alpha:0.7f]
                                                 saturationDeltaFactor:1.0f
                                                             maskImage:nil];
    [self.blurContainerView setImage:blurredSnapshotImage];
}

- (void)updateLayout
{
    [self.blurContainerView setFrame:[self frameForBlurContainer]];
    [self updateBlurContainerContent];
    [[self.menuViewController view] setFrame:[self frameForMenuViewController]];
}

- (void)updateMenuPositionWhilstPanning:(UIPanGestureRecognizer *)recognizer
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (UIWindow *)window
{
    NSString *obfuscatedKey = @"._.s.t.a.t.u.s.B.a.r.W.i.n.d.o.w.";
    NSString *key = [obfuscatedKey stringByReplacingOccurrencesOfString:@"." withString:@""];
    return [[UIApplication sharedApplication] valueForKey:key];
}

@end
