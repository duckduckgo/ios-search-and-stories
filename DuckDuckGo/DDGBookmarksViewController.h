//
//  DDGBookmarksViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import <UIKit/UIKit.h>
#import "DDGSearchHandler.h"
#import "DDGMenuHistoryItemCell.h"

@class DDGSearchController;

@interface DDGBookmarksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DDGHistoryItemCellDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *noBookmarksView;
@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, readwrite, weak) id <DDGSearchHandler> searchHandler;

@end
