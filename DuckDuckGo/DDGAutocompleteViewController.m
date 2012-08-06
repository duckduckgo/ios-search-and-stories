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

@implementation DDGAutocompleteViewController
static NSString *bookmarksCellID = @"BCell";
static NSString *suggestionCellID = @"SCell";
static NSString *historyCellID = @"HCell";
static NSString *emptyCellID = @"ECell";

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
    return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // empty sections shouldn't have headers
    if(![self tableView:tableView numberOfRowsInSection:section])
        return nil;
    
    switch (section) {
        case 0:
            return @"History";
        case 1:
            return @"Suggestions";
        case 2: // we want a separator only if there's something on top of this section
            for(int i=0; i<2; i++)
                if([self tableView:tableView numberOfRowsInSection:i])
                    return @" ";
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
        case 2:
            return 1;
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
     	NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
        cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
        if([suggestionItem objectForKey:@"image"])
            [iv setImageWithURL:[NSURL URLWithString:[suggestionItem objectForKey:@"image"]]];
        else
            [iv setImage:nil]; // wipe out any image that used to be there
        
    } else if(indexPath.section == 2) {
        cell = [tv dequeueReusableCellWithIdentifier:bookmarksCellID];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:bookmarksCellID];
            cell.textLabel.text = @"Saved";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
        }
    }
    
    return cell;
    // TODO: if random crashes show up, add empty-cell code. if not, then delete the dead remaining emptycell code.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        NSArray *history = [[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        [[DDGSearchHistoryProvider sharedProvider] logHistoryItem:[historyItem objectForKey:@"text"]];
        [self.searchController.searchHandler loadQueryOrURL:[historyItem objectForKey:@"text"]];
        
    } else if(indexPath.section == 1) {
        NSArray *suggestions = [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text];
        NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row];
        if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
            [[DDGSearchHistoryProvider sharedProvider] logHistoryItem:[suggestionItem objectForKey:@"phrase"]];
        [self.searchController.searchHandler loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];

    } else if(indexPath.section == 2) {
        DDGBookmarksViewController *bookmarksVC = [[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:bookmarksVC animated:YES];
        
        // as a workaround for a UINavigationController bug, we can't hide the keyboard until after the transition is complete
        double delayInSeconds = 0.4;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.searchController.searchField resignFirstResponder];
        });

    }
}

@end