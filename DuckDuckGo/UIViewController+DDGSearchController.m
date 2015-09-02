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


-(UIView*)alternateToolbar {
    return nil;
}

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

- (void)duckGoToTopLevel
{
    DLog(@"duckToToTopLevel");
}

- (void)reenableScrollsToTop {
    for (UIViewController *v in self.childViewControllers)
        [v reenableScrollsToTop];
}

- (void)clearScrollsToTop:(UIView *)view {
    if([view isKindOfClass:[UIScrollView class]])
        ((UIScrollView *)view).scrollsToTop = NO;
    
    for(UIView *subview in view.subviews)
        [self clearScrollsToTop:subview];
}
@end
