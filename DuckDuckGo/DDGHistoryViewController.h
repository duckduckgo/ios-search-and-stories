//
//  DDGHistoryViewController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 10/04/2013.
//
//

#import <UIKit/UIKit.h>
#import "DDGSearchHandler.h"

@protocol DDGTableViewAdditionalSectionsDelegate <NSObject, UITableViewDataSource, UITableViewDelegate>
- (NSInteger)numberOfAdditionalSections;
@end

@class DDGUnderViewControllerCell;
@interface DDGHistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, weak, readonly) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id <DDGTableViewAdditionalSectionsDelegate> additionalSectionsDelegate;
-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end
