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

typedef enum DDGHistoryViewControllerMode {
    DDGHistoryViewControllerModeNormal = 0,
    DDGHistoryViewControllerModeUnder
} DDGHistoryViewControllerMode;

@class DDGUnderViewControllerCell;
@interface DDGHistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) IBOutlet UIView *noResultsView;
@property (nonatomic, weak, readonly) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id <DDGTableViewAdditionalSectionsDelegate> additionalSectionsDelegate;
@property (nonatomic) BOOL showsHistory;
-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext mode:(DDGHistoryViewControllerMode)mode;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end
