//
//  UIViewController+DDGSearchController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 05/04/2013.
//
//

#import "UIViewController+DDGSearchController.h"
#import "DDGSearchController.h"

@implementation UIViewController (DDGSearchController)
- (DDGSearchController *)searchControllerDDG
{
    UIViewController *viewController = self.parentViewController;
    while (!(viewController == nil || [viewController isKindOfClass:[DDGSearchController class]])) {
        viewController = viewController.parentViewController;
    }
    
    return (DDGSearchController *)viewController;
}

- (UIImage *)searchControllerBackButtonIconDDG {
    return nil;
}
@end
