//
//  DDGSlideOverMenuController.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import <UIKit/UIKit.h>

@interface DDGSlideOverMenuController : UIViewController

@property (nonatomic, assign, readonly, getter = isAnimating) BOOL animating;
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) UIViewController *menuViewController;

@end
