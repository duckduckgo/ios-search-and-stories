//
//  DDGCustomDeleteViewController.h
//  
//
//  Created by Johnnie Walker on 18/04/2013.
//
//

#import <UIKit/UIKit.h>

@interface DDGCustomDeleteViewController : UITableViewController <UITableViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSMutableSet *deletingIndexPaths;
- (void)cancelDeletingIndexPathsAnimated:(BOOL)animated;
@end
