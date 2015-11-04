//
//  DDGTabViewController.h
//  SyncSpace
//
//  Created by Johnnie Walker on 14/12/2011.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDGSegmentedControl.h"

typedef enum DDGTabViewControllerToolbarPosition {
    DDGTabViewControllerControlViewPositionTop,
    DDGTabViewControllerControlViewPositionBottom,    
} DDGTabViewControllerControlViewPosition;

@class DDGTabViewController;
@protocol DDGTabViewControllerDelegate <NSObject>
@optional
- (void)tabViewController:(DDGTabViewController *)tabViewController didSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)tabIndex;
@end

@interface DDGTabViewController : UIViewController {}

@property (nonatomic, weak) UIView* segmentAlignmentView;
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, weak, readonly) UIViewController *currentViewController;
@property (nonatomic) NSInteger currentViewControllerIndex;
@property (nonatomic, weak) id <DDGTabViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *searchControllerBackButtonIconDDG;

@end
