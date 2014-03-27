//
//  DDGSlideOverMenuController.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import <UIKit/UIKit.h>

extern NSString * const DDGSlideOverMenuWillAppearNotification;
extern NSString * const DDGSlideOverMenuDidAppearNotification;

@interface DDGSlideOverMenuController : UIViewController

@property (nonatomic, assign, readonly, getter = isAnimating) BOOL animating;
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) UIViewController *menuViewController;
@property (nonatomic, assign, readonly, getter = isShowingMenu) BOOL showingMenu;

- (void)hideMenu;
- (void)hideMenu:(BOOL)animated;
- (void)showMenu;
- (void)showMenu:(BOOL)animated;

@end
