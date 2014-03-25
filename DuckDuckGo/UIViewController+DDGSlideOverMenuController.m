//
//  UIViewController+DDGSlideOverMenuController.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 25/03/2014.
//
//

#import "UIViewController+DDGSlideOverMenuController.h"

@implementation UIViewController (DDGSlideOverMenuController)

- (DDGSlideOverMenuController *)slideOverMenuController
{
    UIViewController *viewController = self.parentViewController ? self.parentViewController : self.presentingViewController;
    while (!(viewController == nil || [viewController isKindOfClass:[DDGSlideOverMenuController class]])) {
        viewController = viewController.parentViewController ? viewController.parentViewController : viewController.presentingViewController;
    }
    return (DDGSlideOverMenuController *)viewController;
}

@end
