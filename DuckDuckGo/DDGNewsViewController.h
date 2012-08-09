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
#import <CoreData/CoreData.h>

@interface DDGNewsViewController : UIViewController<UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, DDGSearchHandler, EGORefreshTableHeaderDelegate, UIScrollViewDelegate, NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *fetchedResultsController;
    
    EGORefreshTableHeaderView *refreshHeaderView;
    UIImageView *topShadow;
    BOOL isRefreshing;
}

@property (nonatomic, strong) IBOutlet UITableViewCell *loadedCell;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) DDGSearchController *searchController;

@end