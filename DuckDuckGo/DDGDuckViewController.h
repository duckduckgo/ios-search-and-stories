//
//  DDGDuckViewController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import <UIKit/UIKit.h>
#import "DDGHistoryProvider.h"
#import "DDGSearchSuggestionsProvider.h"

@class DDGSearchController;

@interface DDGDuckViewController : UITableViewController

@property (nonatomic, strong) DDGHistoryProvider *historyProvider;

- (instancetype)initWithSearchController:(DDGSearchController *)searchController
                    managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)updateContainerHeightConstraint:(BOOL)keyboardShowing;

- (void)searchFieldDidChange:(id)sender;

@end
