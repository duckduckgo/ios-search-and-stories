//
//  DDGAutocompleteViewController.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/4/12.
//
//

#import <UIKit/UIKit.h>
#import "DDGHistoryProvider.h"
#import "DDGSearchSuggestionsProvider.h"

@interface DDGAutocompleteViewController : UITableViewController
@property (nonatomic, strong) DDGHistoryProvider *historyProvider;

-(void)searchFieldDidChange:(id)sender;
-(void)tableViewBackgroundTouched;

@end
