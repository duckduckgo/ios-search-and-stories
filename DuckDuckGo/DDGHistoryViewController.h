//
//  DDGHistoryViewController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 10/04/2013.
//
//

#import <UIKit/UIKit.h>
#import "DDGSearchHandler.h"

@interface DDGHistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, weak, readonly) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end
