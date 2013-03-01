//
//  DDGViewController.h
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDGSearchController.h"
#import "EGORefreshTableHeaderView.h"

@class DDGStoryCell;
@class DDGScrollbarClockView;
@interface DDGHomeViewController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, DDGSearchHandler, EGORefreshTableHeaderDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    EGORefreshTableHeaderView *refreshHeaderView;
    UIImageView *topShadow;
    BOOL isRefreshing;
}

@property (nonatomic, strong) IBOutlet DDGStoryCell *loadedCell;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) DDGSearchController *searchController;
@property (strong, nonatomic) IBOutlet UIView *swipeView;
@property (weak, nonatomic) IBOutlet UIButton *swipeViewSaveButton;

@end