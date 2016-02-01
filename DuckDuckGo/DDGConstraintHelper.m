//
//  DDGConstraintHelper.m
//  DuckDuckGo
//
//  Created by Josiah Clumont on 1/02/16.
//
//

#import "DDGConstraintHelper.h"

@implementation DDGConstraintHelper


+ (void)setHeight:(CGFloat)height ofView:(UIView*)viewToAddHeight inViewContainer:(UIView*)viewContainer {
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToAddHeight attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height]];
}

+ (void)pinView:(UIView*)viewToPin underView:(UIView*)viewToPinUnder inViewContainer:(UIView*)viewContainer {
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:viewToPinUnder attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
}

+ (void)pinView:(UIView*)viewToPin toEdgeOfView:(UIView*)viewToPinEdgesTo inViewContainer:(UIView*)viewContainer {
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:viewToPinEdgesTo attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:viewToPinEdgesTo attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
}

// Method to quickly add constraints to pin a view to another view that are both subviews of another view, so that a view can change and the viewToPin will change acordingly
+ (void)pinView:(UIView*)viewToPin toView:(UIView*)viewToPinTo inViewContainer:(UIView*)viewContainer {
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:viewToPinTo attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:viewToPinTo attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:viewToPinTo attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [viewContainer addConstraint:[NSLayoutConstraint constraintWithItem:viewToPin attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:viewToPinTo attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
}
@end
