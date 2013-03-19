//
//  DDGStoriesViewController.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "DDGSearchHandler.h"
#import "DDGSearchController.h"
#import "EGORefreshTableHeaderView.h"

@interface DDGStoriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, EGORefreshTableHeaderDelegate, UIScrollViewDelegate, NSFetchedResultsControllerDelegate>
{}
@property (nonatomic, readonly, weak) id <DDGSearchHandler> searchHandler;
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;

- (id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end
