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

@interface DDGDuckViewController : UIViewController

@property (nonatomic, strong) DDGHistoryProvider *historyProvider;
@property BOOL popoverMode;
@property BOOL underPopoverMode;
@property BOOL showsOnboarding;

- (instancetype)initWithSearchController:(DDGSearchController *)searchController
                    managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)updateContainerHeightConstraint:(BOOL)keyboardShowing;

- (void)searchFieldDidChange:(id)sender;
- (void)setBottomPaddingBy:(CGFloat)paddingHeight;

@end
