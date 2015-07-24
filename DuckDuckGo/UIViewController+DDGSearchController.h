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

@property (readonly) UIView* alternateToolbar;

- (DDGSearchController *)searchControllerDDG;
- (UIImage *)searchControllerBackButtonIconDDG;
- (UIView*)alternateToolbar;
- (void)reenableScrollsToTop;   // overridden by subclasses who want scrollsToTop
- (void)clearScrollsToTop:(UIView *)view;
@end
