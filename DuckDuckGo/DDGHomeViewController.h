//
//  DDGHomeViewController.h
//  DuckDuckGo
//
//  Created by Sean Reilly on 26/06/2015.
//
//

#import <UIKit/UIKit.h>

#import "DDGSearchHandler.h"
#import "DDGTabViewController.h"


@interface DDGHomeViewController : UIViewController <DDGSearchHandler, DDGTabViewControllerDelegate, UITabBarControllerDelegate>

@property (nonatomic, copy) void (^viewDidAppearCompletion)(DDGHomeViewController *homeController);
@property (nonatomic, strong) UIView* alternateButtonBar;

+(DDGHomeViewController*)newHomeController;

@end
