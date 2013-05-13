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
#import "DDGSettingsViewController.h"
#import "DDGPlusButton.h"

@interface DDGAutocompleteViewController ()
@property (nonatomic, copy) NSArray *suggestions;
@end

@implementation DDGAutocompleteViewController

// static NSString *bookmarksCellID = @"BCell";
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
    
    DDGSearchSuggestionsProvider *provider = [DDGSearchSuggestionsProvider sharedProvider];
    NSString *searchText = self.searchController.searchBar.searchField.text;
    self.suggestions = @[];
    [provider downloadSuggestionsForSearchText:searchText success:^{
        if ([searchText isEqual:self.searchController.searchBar.searchField.text]) {
            self.suggestions = [provider suggestionsForSearchText:searchText];
            [self.tableView reloadData];
        }
    }];
}

- (IBAction)plus:(id)sender {
    UIButton *button = nil;
    if ([sender isKindOfClass:[UIButton class]])
        button = (UIButton *)sender;
    
    if (button) {
        CGPoint tappedPoint = [self.tableView convertPoint:button.center fromView:button.superview];
        NSIndexPath *tappedIndex = [self.tableView indexPathForRowAtPoint:tappedPoint];
        NSDictionary *suggestionItem = [self.suggestions objectAtIndex:tappedIndex.row];
        DDGSearchController *searchController = [self searchControllerDDG];
        if (searchController) {
            DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
            [searchField becomeFirstResponder];
            searchField.text = [suggestionItem objectForKey:@"phrase"];
            [searchController searchFieldDidChange:nil];
        }
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(DDGSearchController *)searchController {
    return (DDGSearchController *)self.navigationController.parentViewController;
}

- (void)searchFieldDidChange:(id)sender {
    NSString *newSearchText = self.searchController.searchBar.searchField.text;
        
    if([newSearchText isEqualToString:[self.searchController validURLStringFromString:newSearchText]]) {
        // we're definitely editing a URL, don't bother with autocomplete.
        return;
    }
    
	if (newSearchText.length) {
		// load our new best cached result, and download new autocomplete suggestions.
        DDGSearchSuggestionsProvider *provider = [DDGSearchSuggestionsProvider sharedProvider];
        [provider downloadSuggestionsForSearchText:newSearchText success:^{
            if ([newSearchText isEqual:self.searchController.searchBar.searchField.text]) {
                self.suggestions = [provider suggestionsForSearchText:newSearchText];
                [self.tableView reloadData];
            }
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
	if (!section && ![self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text].count)
		return nil;
	else if (section == 1 && !self.suggestions.count)
		return nil;

	UILabel *hv = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 23.0)];
	
	hv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"section_tile.png"]];
	hv.textColor = [UIColor  colorWithRed:0x77/255.0 green:0x74/255.0 blue:0x7E/255.0 alpha:1.0];
	hv.shadowColor = [UIColor whiteColor];
	hv.shadowOffset = CGSizeMake(0.5, 0.5);
	hv.font = [UIFont boldSystemFontOfSize:14.0];
	hv.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	if (!section)
		hv.text = @" Recent";
	else
		hv.text = @" Suggestions";
	return hv;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (!section && [self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text].count)
		return 23.0;
	if (section == 1 && self.suggestions.count)
		return 23.0;
	
	return 0.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
	{
        case 0:
            return [self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text].count;
        case 1:
            return self.suggestions.count;
    }
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	BOOL lineHidden = NO;
    
    if(indexPath.section == 0) {
        cell = [tv dequeueReusableCellWithIdentifier:historyCellID];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellID];
            cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0];
            cell.textLabel.textColor = [UIColor  colorWithRed:0x9F/255.0 green:0xA7/255.0 blue:0xB4/255.0 alpha:1.0]; // #9FA7B4
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
        
        NSArray *history = [self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text];
        DDGHistoryItem *historyItem = [history objectAtIndex:indexPath.row];
        
        cell.textLabel.text = historyItem.title;
        
		lineHidden = (indexPath.row == [self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text].count - 1) ? YES : NO;
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
			[cell addSubview:separatorLine];
        }
		else
		{
            iv = (UIImageView *)[cell.contentView viewWithTag:100];
        }
		
		lineHidden = (indexPath.row == self.suggestions.count - 1) ? YES : NO;

        NSArray *suggestions = self.suggestions;

        // the tableview sometimes requests rows that don't exist. in this case the table's reloading anyway so just return whatever and don't crash.
        NSDictionary *suggestionItem;
        if(indexPath.row < suggestions.count)
            suggestionItem = [suggestions objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
        cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
        UIButton *button = [DDGPlusButton lightPlusButton];
        [button addTarget:self action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
        
        if([suggestionItem objectForKey:@"image"])
		{
            NSLog(@"imageURL: %@", [suggestionItem objectForKey:@"image"]);
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
	if (!indexPath.section && [self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text].count)
		return kCellHeightHistory+1;
	else if (indexPath.section == 1 && self.suggestions.count)
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
	{
        NSArray *history = [self.historyProvider pastHistoryItemsForPrefix:self.searchController.searchBar.searchField.text];        
        DDGHistoryItem *item = [history objectAtIndex:indexPath.row];
        [self.historyProvider relogHistoryItem:item];
        DDGStory *story = item.story;
        int readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
        if (item.story) {
            [self.searchController loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
        } else {
            [self.searchController loadQueryOrURL:item.title];
        }
        
        [self.searchController dismissAutocomplete];
    }
	else if (indexPath.section == 1)
	{
        NSArray *suggestions = self.suggestions;
        NSDictionary *suggestionItem = [suggestions objectAtIndex:indexPath.row];
        if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
            [self.historyProvider logSearchResultWithTitle:[suggestionItem objectForKey:@"phrase"]];
        [self.searchController loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];
        [self.searchController dismissAutocomplete];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSArray *suggestions = self.suggestions;
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
        [self.searchController.searchBar.searchField resignFirstResponder];
    });
}

@end
