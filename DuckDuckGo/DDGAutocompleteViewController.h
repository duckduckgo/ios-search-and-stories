//
//  DDGAutocompleteViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/4/12.
//
//

#import <UIKit/UIKit.h>
#import "DDGSearchHistoryProvider.h"
#import "DDGSearchSuggestionsProvider.h"

@interface DDGAutocompleteViewController : UITableViewController

-(void)searchFieldDidChange:(id)sender;

@end
