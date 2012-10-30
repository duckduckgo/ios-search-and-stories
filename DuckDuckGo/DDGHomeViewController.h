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

@class DDGScrollbarClockView;
@interface DDGHomeViewController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, DDGSearchHandler, EGORefreshTableHeaderDelegate, UIScrollViewDelegate> {
    EGORefreshTableHeaderView *refreshHeaderView;
    UIImageView *topShadow;
    BOOL isRefreshing;
    
    UIColor *linen;

    UIColor *cellOverlayPatternColor;
}

@property (nonatomic, strong) UIColor *cellOverlayPatternColor;

@property (nonatomic, strong) IBOutlet UITableViewCell *loadedCell;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) DDGSearchController *searchController;

@end