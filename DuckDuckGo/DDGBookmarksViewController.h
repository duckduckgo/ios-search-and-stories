//
//  DDGBookmarksViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import <UIKit/UIKit.h>
#import "DDGSearchHandler.h"
#import "DDGCustomDeleteViewController.h"

@class DDGSearchController;

@interface DDGBookmarksViewController : DDGCustomDeleteViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *noBookmarksView;
@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, readwrite, weak) id <DDGSearchHandler> searchHandler;

- (IBAction)plus:(id)sender;

@end
