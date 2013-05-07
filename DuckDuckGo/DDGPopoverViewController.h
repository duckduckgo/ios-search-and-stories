//
//  DDGPopoverViewController.h
//  Popover
//
//  Created by Johnnie Walker on 07/05/2013.
//  Copyright (c) 2013 Random Sequence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DDGPopoverViewController : UIViewController
@property (nonatomic, strong, readonly) UIViewController *contentViewController;

- (id)initWithContentViewController:(UIViewController *)viewController;

- (void)presentPopoverFromRect:(CGRect)rect
                        inView:(UIView *)view
      permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                      animated:(BOOL)animated;

- (void)dismissPopoverAnimated:(BOOL)animated;

@end
