//
//  UIViewController+DDGSearchController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 05/04/2013.
//
//

#import <UIKit/UIKit.h>

@class DDGSearchController;
@interface UIViewController (DDGSearchController) {
    
}
- (DDGSearchController *)searchControllerDDG;
- (UIImage *)searchControllerBackButtonIconDDG;
- (void)reenableScrollsToTop;   // overridden by subclasses who want scrollsToTop
- (void)clearScrollsToTop:(UIView *)view;
@end
