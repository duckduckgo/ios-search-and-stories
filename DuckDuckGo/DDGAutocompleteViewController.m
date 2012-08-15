//
//  DDGAutocompleteViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/4/12.
//
//

#import "DDGAutocompleteViewController.h"
#import "DDGAutocompleteTableView.h"
#import "DDGSearchController.h"
#import "DDGAddressBarTextField.h"
#import "AFNetworking.h"
#import "DDGBookmarksViewController.h"
#import "DDGTier2ViewController.h"

@implementation DDGAutocompleteViewController
static NSString *bookmarksCellID = @"BCell";
static NSString *suggestionCellID = @"SCell";
static NSString *historyCellID = @"HCell";

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // use our custom table view class
    self.tableView = [[DDGAutocompleteTableView alloc] initWithFrame:self.tableView.frame
                                                               style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.scrollsToTop = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [[DDGSearchSuggestionsProvider sharedProvider] downloadSuggestionsForSearchText:self.searchController.searchField.text success:^{
        [self.tableView reloadData];
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(DDGSearchController *)searchController {
    return (DDGSearchController *)self.navigationController.parentViewController;
}

- (void)searchFieldDidChange:(id)sender {
    NSString *newSearchText = self.searchController.searchField.text;
    
    if([newSearchText isEqualToString:[self.searchController validURLStringFromString:newSearchText]]) {
        // we're definitely editing a URL, don't bother with autocomplete.
        return;
    }
    
	if(newSearchText.length) {
		// load our new best cached result, and download new autocomplete suggestions.
        [[DDGSearchSuggestionsProvider sharedProvider] downloadSuggestionsForSearchText:newSearchText success:^{
            [self.tableView reloadData];
        }];
	} else {
        // search text is blank; clear the suggestions cache, reload, and hide the table
        [[DDGSearchSuggestionsProvider sharedProvider] emptyCache];
    }
    // either way, reload the table view.
    [self.tableView reloadData];
}

-(void)tableViewBackgroundTouched {
    [self.searchController dismissAutocomplete];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // empty sections shouldn't have headers
    if(![self tableView:tableView numberOfRowsInSection:section])
        return nil;
    
    switch (section) {
        case 0: // return "History" if there's stuff in the section, nil otherwise
            if([self tableView:tableView numberOfRowsInSection:section])
                return @"History";
            else
                return nil;
        case 1: // return "Suggestions" if there's stuff in the section AND there's a history section, nil otherwise
            if([self tableView:tableView numberOfRowsInSection:section] && [self tableView:tableView numberOfRowsInSection:0])
                return @"Suggestions";
            else
                return nil;
        default:
            return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text].count;
        case 1:
            return [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text].count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if(indexPath.section == 0) {
        cell = [tv dequeueReusableCellWithIdentifier:historyCellID];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
        }
        
        NSArray *history = [[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [historyItem objectForKey:@"text"];
        
    } else if(indexPath.section == 1) {
        cell = [tv dequeueReusableCellWithIdentifier:suggestionCellID];
        UIImageView *iv;
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:suggestionCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.imageView.image = [UIImage imageNamed:@"spacer44x44.png"];
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
            
            iv = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
            iv.tag = 100;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            iv.backgroundColor = [UIColor whiteColor];
            [cell.contentView addSubview:iv];
        } else {
            iv = (UIImageView *)[cell.contentView viewWithTag:100];
        }
        
        NSArray *suggestions = [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text];

        // the tableview sometimes requests rows that don't exist. in this case the table's reloading anyway so just return whatever and don't crash.
        NSDictionary *suggestionItem;
        if(indexPath.row < suggestions.count)
            suggestionItem = [suggestions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
        cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
        
        if([suggestionItem objectForKey:@"image"])
            [iv setImageWithURL:[NSURL URLWithString:[suggestionItem objectForKey:@"image"]]];
        else
            [iv setImage:nil]; // wipe out any image that used to be there
        
        if([suggestionItem objectForKey:@"calls"] && [[suggestionItem objectForKey:@"calls"] count])
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;

        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        NSArray *history = [[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        [[DDGSearchHistoryProvider sharedProvider] logHistoryItem:[historyItem objectForKey:@"text"]];
        [self.searchController.searchHandler loadQueryOrURL:[historyItem objectForKey:@"text"]];
        [self.searchController dismissAutocomplete];
    } else if(indexPath.section == 1) {
        NSArray *suggestions = [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text];
        NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row];
        if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
            [[DDGSearchHistoryProvider sharedProvider] logHistoryItem:[suggestionItem objectForKey:@"phrase"]];
        [self.searchController.searchHandler loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];
        [self.searchController dismissAutocomplete];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSArray *suggestions = [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text];
    NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row];

    DDGTier2ViewController *tier2VC = [[DDGTier2ViewController alloc] initWithSuggestionItem:suggestionItem];
    [self.navigationController pushViewController:tier2VC animated:YES];
    [self hideKeyboardAfterDelay];
    
}

-(void)hideKeyboardAfterDelay {
    // as a workaround for a UINavigationController bug, we can't hide the keyboard until after the transition is complete
    double delayInSeconds = 0.4;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.searchController.searchField resignFirstResponder];
    });
}

@end