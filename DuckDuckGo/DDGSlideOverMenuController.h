//
//  DDGSlideOverMenuController.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DDGSlideOverMenuMode) {
    DDGSlideOverMenuModeHorizontal = 0,
    DDGSlideOverMenuModeVertical
};

extern NSString * const DDGSlideOverMenuWillAppearNotification;
extern NSString * const DDGSlideOverMenuDidAppearNotification;

@interface DDGSlideOverMenuController : UIViewController

@property (nonatomic, assign, readonly, getter = isAnimating) BOOL animating;
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) UIViewController *menuViewController;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign, readonly, getter = isShowingMenu) BOOL showingMenu;

- (instancetype)initWithMode:(DDGSlideOverMenuMode)mode;

- (void)hideMenu;
- (void)hideMenu:(BOOL)animated;
- (void)hideMenu:(BOOL)animated completion:(void(^)())completion;
- (void)showMenu;
- (void)showMenu:(BOOL)animated;

@end
