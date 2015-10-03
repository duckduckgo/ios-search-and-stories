//
//  DDGPopoverViewController.h
//  Popover
//
//  Created by Johnnie Walker on 07/05/2013.
//  Copyright (c) 2013 Random Sequence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class DDGPopoverViewController;
@protocol DDGPopoverViewControllerDelegate <NSObject>
- (void)popoverControllerDidDismissPopover:(DDGPopoverViewController *)popoverController;
@end


@interface DDGPopoverViewController : UIViewController
@property (nonatomic, strong, readonly) UIViewController *contentViewController;
@property (nonatomic, weak) UIViewController *popoverParentController;
@property (nonatomic, weak) id <DDGPopoverViewControllerDelegate> delegate;
@property (nonatomic, assign) CGFloat intrusion;
@property (nonatomic) BOOL shouldDismissUponOutsideTap;
@property (nonatomic) BOOL shouldAbsorbAndDismissUponDimmedViewTap;
@property (nonatomic) BOOL hideArrow;
@property (nonatomic) BOOL largeMode;
@property (nonatomic, weak) UIView* dimmedBackgroundView;
@property (nonatomic) CGRect anchorRect;

- (id)initWithContentViewController:(UIViewController *)viewController
            andTouchPassthroughView:(UIView*)backgroundView;

- (void)presentPopoverFromView:(UIView *)originView
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated;

- (void)presentPopoverFromRect:(CGRect)originRect
                        inView:(UIView *)originView
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated;

- (void)dismissPopoverAnimated:(BOOL)animated;

@end
