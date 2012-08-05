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
    
    suggestionsProvider = [[DDGSearchSuggestionsProvider alloc] init];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
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
        [suggestionsProvider downloadSuggestionsForSearchText:newSearchText success:^{
            [self.tableView reloadData];
        }];
	} else {
        // search text is blank; clear the suggestions cache, reload, and hide the table
        [suggestionsProvider emptyCache];
    }
    // either way, reload the table view.
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if([self.searchController.searchField.text isEqualToString:@""])
        return 1;
    else
        return ([[suggestionsProvider suggestionsForSearchText:self.searchController.searchField.text] count] +
                [[[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text] count]);
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.searchController.searchField.text isEqualToString:@""]) {
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:bookmarksCellID];
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
        return cell;
    }
    
    NSArray *history = [[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
    NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:self.searchController.searchField.text];
    if((suggestions.count + history.count) <= indexPath.row) {
        // this entry no longer exists; return empty cell. the tableview will be reloading very soon anyway.
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:emptyCellID];
        if(cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:emptyCellID];
        return cell;
    }
    
    UITableViewCell *cell;
    if(indexPath.row < history.count) {
        // dequeue or initialize a history cell
        cell = [tv dequeueReusableCellWithIdentifier:historyCellID];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
        }
        
        // fill the appropriate data into the history cell
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        cell.textLabel.text = [historyItem objectForKey:@"text"];
        //cell.detailTextLabel.text = @"History item";
        
    } else {
        // dequeue or initialize a suggestion cell
        cell = [tv dequeueReusableCellWithIdentifier:suggestionCellID];
        UIImageView *iv;
        if(cell == nil) {
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
        
     	NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row - history.count];
        
        cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
        cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
        
        if([suggestionItem objectForKey:@"image"])
            [iv setImageWithURL:[NSURL URLWithString:[suggestionItem objectForKey:@"image"]]];
        else
            [iv setImage:nil]; // wipe out any image that used to be there
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[[tv cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:bookmarksCellID]) {
        DDGBookmarksViewController *bookmarksVC = [[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:bookmarksVC animated:YES];
    } else {
        NSArray *history = [[DDGSearchHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
        NSArray *suggestions = [suggestionsProvider suggestionsForSearchText:self.searchController.searchField.text];
        if(indexPath.row < history.count) {
            NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
            [self.searchController loadQueryOrURL:[historyItem objectForKey:@"text"]];
        } else {
            NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row - history.count];
            if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
                [self.searchController loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];
        }
        
        [tv deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    [self.searchController.searchField resignFirstResponder];
}

-(void)tableViewBackgroundTouched {
    [self.searchController dismissAutocomplete];
}

@end
