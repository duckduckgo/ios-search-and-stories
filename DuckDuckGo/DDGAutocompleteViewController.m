//
//  DDGAutocompleteViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/4/12.
//
//

#import <QuartzCore/QuartzCore.h>

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

#define kCellHeightHistory			44.0
#define kCellHeightSuggestions		62.0

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
    
	if (newSearchText.length) {
		// load our new best cached result, and download new autocomplete suggestions.
        [[DDGSearchSuggestionsProvider sharedProvider] downloadSuggestionsForSearchText:newSearchText success:^{
            [self.tableView reloadData];
        }];
	}
	else
	{
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

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (!section && ![[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text].count)
		return nil;
	else if (section == 1 && ![[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text].count)
		return nil;

	UILabel *hv = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 23.0)];
	
	hv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section_tile.png"]];
	hv.textColor = [UIColor  colorWithRed:0x77/255.0 green:0x74/255.0 blue:0x7E/255.0 alpha:1.0];
	hv.shadowColor = [UIColor whiteColor];
	hv.shadowOffset = CGSizeMake(0.5, 0.5);
	hv.font = [UIFont boldSystemFontOfSize:14.0];
	hv.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	if (!section)
		hv.text = @" History";
	else
		hv.text = @" Suggestions";
	return hv;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (!section && [[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text].count)
		return 23.0;
	if (section == 1 && [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text].count)
		return 23.0;
	
	return 0.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
	{
        case 0:
            return [[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text].count;
        case 1:
            return [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text].count;
    }
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	BOOL lineHidden;
    
    if(indexPath.section == 0) {
        cell = [tv dequeueReusableCellWithIdentifier:historyCellID];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];

			// self contained separator lines
			UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeightHistory, tv.frame.size.width, 1.0)];
			separatorLine.clipsToBounds = YES;
			separatorLine.backgroundColor = [UIColor lightGrayColor];
			separatorLine.tag = 200;
			[cell.contentView addSubview:separatorLine];
        }
        
        NSArray *history = [[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [historyItem objectForKey:@"text"];
        
		lineHidden = (indexPath.row == [[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text].count - 1) ? YES : NO;
    }
	else if(indexPath.section == 1)
	{
        cell = [tv dequeueReusableCellWithIdentifier:suggestionCellID];
        UIImageView *iv;
        if(!cell)
		{
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:suggestionCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
            cell.textLabel.textColor = [UIColor  colorWithRed:0x54/255.0 green:0x59/255.0 blue:0x5F/255.0 alpha:1.0];
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.imageView.image = [UIImage imageNamed:@"spacer64x64.png"];
			
			cell.detailTextLabel.numberOfLines = 2;
			cell.detailTextLabel.textColor = [UIColor colorWithRed:0x7C/255.0 green:0x85/255.0 blue:0x94/255.0 alpha:1.0];
			
            cell.backgroundView = [[UIView alloc] init];
            [cell.backgroundView setBackgroundColor:[UIColor whiteColor]];
            
            iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 53, 53)];
            iv.tag = 100;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            iv.backgroundColor = [UIColor whiteColor];

			CALayer *layer = iv.layer;
			layer.borderWidth = 0.5;
			layer.borderColor = [UIColor lightGrayColor].CGColor;
			layer.cornerRadius = 3.0;
			
            [cell.contentView addSubview:iv];
			
			// self contained separator lines
			UIView *separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeightSuggestions, tv.frame.size.width, 1.0)];
			separatorLine.clipsToBounds = YES;
			separatorLine.backgroundColor = [UIColor lightGrayColor];
			separatorLine.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
			separatorLine.tag = 200;
			[cell.contentView addSubview:separatorLine];
        }
		else
		{
            iv = (UIImageView *)[cell.contentView viewWithTag:100];
        }
		
		lineHidden = (indexPath.row == [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text].count - 1) ? YES : NO;

        NSArray *suggestions = [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text];

        // the tableview sometimes requests rows that don't exist. in this case the table's reloading anyway so just return whatever and don't crash.
        NSDictionary *suggestionItem;
        if(indexPath.row < suggestions.count)
            suggestionItem = [suggestions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
        cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
        
        if([suggestionItem objectForKey:@"image"])
		{
            [iv setImageWithURL:[NSURL URLWithString:[suggestionItem objectForKey:@"image"]]];
			iv.hidden = NO;
		}
        else
		{
            [iv setImage:nil]; // wipe out any image that used to be there
			iv.hidden = YES;
		}
        
        if([suggestionItem objectForKey:@"calls"] && [[suggestionItem objectForKey:@"calls"] count])
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
	
	[cell.contentView viewWithTag:200].hidden = lineHidden;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section && [[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text].count)
		return kCellHeightHistory+1;
	else if (indexPath.section == 1 && [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text].count)
		return kCellHeightSuggestions+1;

	return 0.0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1)
	{
		UIView *iv = [cell.contentView viewWithTag:100];
		iv.center = cell.imageView.center;
	}
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        NSArray *history = [[DDGHistoryProvider sharedProvider] pastHistoryItemsForPrefix:self.searchController.searchField.text];
        NSDictionary *historyItem = [history objectAtIndex:indexPath.row];
        [[DDGHistoryProvider sharedProvider] logHistoryItem:[historyItem objectForKey:@"text"]];
        [self.searchController.searchHandler loadQueryOrURL:[historyItem objectForKey:@"text"]];
        [self.searchController dismissAutocomplete];
    } else if(indexPath.section == 1) {
        NSArray *suggestions = [[DDGSearchSuggestionsProvider sharedProvider] suggestionsForSearchText:self.searchController.searchField.text];
        NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row];
        if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
            [[DDGHistoryProvider sharedProvider] logHistoryItem:[suggestionItem objectForKey:@"phrase"]];
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