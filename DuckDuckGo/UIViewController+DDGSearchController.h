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
- (UIView*)dimmableContentView; // the view that should be dimmed if a DDGPopoverViewController is shown from this VC
- (void)duckGoToTopLevel; // go to the top level, or at least up a level from the current position

- (CGFloat)duckPopoverIntrusionAdjustment; // override this to shift the autocompletion popover up or down a bit on iPad
@end
