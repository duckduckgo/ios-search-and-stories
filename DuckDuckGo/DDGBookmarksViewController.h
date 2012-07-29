//
//  DDGBookmarksViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import <UIKit/UIKit.h>

@class DDGSearchController;
@interface DDGBookmarksViewController : UITableViewController

@property(nonatomic, weak) DDGSearchController *searchController;

@end
