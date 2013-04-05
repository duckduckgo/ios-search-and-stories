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
- (void)viewMightDisappearDDG;
@end
