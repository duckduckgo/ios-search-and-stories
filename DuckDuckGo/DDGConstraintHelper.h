//
//  DDGConstraintHelper.h
//  DuckDuckGo
//
//  Created by Josiah Clumont on 1/02/16.
//
//

#import <Foundation/Foundation.h>

@interface DDGConstraintHelper : NSObject

+ (void)pinView:(UIView*)viewToPin toView:(UIView*)viewToPinTo inViewContainer:(UIView*)viewContainer;
+ (void)setHeight:(CGFloat)height ofView:(UIView*)viewToAddHeight inViewContainer:(UIView*)viewContainer;
+ (void)pinView:(UIView*)viewToPin toEdgeOfView:(UIView*)viewToPinEdgesTo inViewContainer:(UIView*)viewContainer;
+ (void)pinView:(UIView*)viewToPin underView:(UIView*)viewToPinUnder inViewContainer:(UIView*)viewContainer;
+ (void)pinView:(UIView*)viewToPin intoView:(UIView*)viewToPinInto;
+ (void)pinView:(UIView*)viewToPin toBottomOfView:(UIView*)viewToPinBottomTo inViewController:(UIView*)viewContainer;
@end
