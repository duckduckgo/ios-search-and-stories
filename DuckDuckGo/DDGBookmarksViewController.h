//
//  DDGBookmarksViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import <UIKit/UIKit.h>

@interface DDGBookmarksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *noBookmarksView;
@end
