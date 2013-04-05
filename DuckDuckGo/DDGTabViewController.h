//
//  DDGTabViewController.h
//  SyncSpace
//
//  Created by Johnnie Walker on 14/12/2011.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum DDGTabViewControllerToolbarPosition {
    DDGTabViewControllerControlViewPositionNone = 0,
    DDGTabViewControllerControlViewPositionTop,
    DDGTabViewControllerControlViewPositionBottom,    
} DDGTabViewControllerControlViewPosition;

@class DDGTabViewController;
@protocol DDGTabViewControllerDelegate <NSObject>
@optional
- (void)tabViewController:(DDGTabViewController *)tabViewController didSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)tabIndex;
@end

@interface DDGTabViewController : UIViewController {}

@property (nonatomic, strong, readonly) UISegmentedControl *segmentedControl;
@property (nonatomic, copy, readonly) NSArray *viewControllers;
@property (nonatomic, weak, readonly) UIViewController *currentViewController;
@property (nonatomic) NSInteger currentViewControllerIndex;
@property (nonatomic, strong) UIView *controlView;
@property (nonatomic) DDGTabViewControllerControlViewPosition controlViewPosition;
@property (nonatomic, weak) id <DDGTabViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *searchControllerBackButtonIconDDG;

- (id)initWithViewControllers:(NSArray *)viewControllers;
@end
