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
#import "DDGAutocompleteCell.h"
#import "DDGAutocompleteHeaderView.h"

@interface DDGAutocompleteViewController ()
@property (nonatomic, copy) NSArray *history;
@property (nonatomic, copy) NSArray *suggestions;
@property (nonatomic, strong) NSOperationQueue *imageRequestQueue;
@property (nonatomic, strong) NSCache *imageCache;
@end

@implementation DDGAutocompleteViewController

// static NSString *bookmarksCellID = @"BCell";
static NSString *suggestionCellID = @"SCell";
static NSString *historyCellID = @"HCell";

#define kCellHeightHistory			44.0
#define kCellHeightSuggestions		66.0

- (void)dealloc
{
    [self.imageRequestQueue cancelAllOperations];
    self.imageRequestQueue = nil;
}

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
    
    self.imageCache = [NSCache new];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 4;
    self.imageRequestQueue = queue;
    
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.imageCache removeAllObjects];
    
    [self.imageRequestQueue cancelAllOperations];
    self.imageRequestQueue = nil;
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

- (void)setSuggestions:(NSArray *)suggestions {
    if (suggestions == _suggestions)
        return;
    
    [self.imageRequestQueue cancelAllOperations];
    
    _suggestions = [suggestions copy];    
    [self.tableView reloadData];
    
    for (NSDictionary *suggestionItem in suggestions) {
        if([[suggestionItem objectForKey:@"image"] length]) {
            NSURL *URL = [NSURL URLWithString:[suggestionItem objectForKey:@"image"]];
            if (nil != URL && nil == [self.imageCache objectForKey:URL]) {                
                __weak DDGAutocompleteViewController *weakSelf = self;
                void (^success)(UIImage *image) = ^(UIImage *image) {
                    [weakSelf.imageCache setObject:image forKey:URL];
                    NSUInteger row = [weakSelf.suggestions indexOfObject:suggestionItem];
                    if (row != NSNotFound) {
                        DDGAutocompleteCell *cell = (DDGAutocompleteCell *)[weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
                        cell.roundedImageView.image = image;
                        [cell setNeedsLayout];
                    }
                };
                
                AFImageRequestOperation *imageOperation = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:URL]
                                                                                                            success:success];
                [self.imageRequestQueue addOperation:imageOperation];
            }
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
        self.history = [self.historyProvider pastHistoryItemsForPrefix:newSearchText];
        
        __weak DDGAutocompleteViewController *weakSelf = self;
        
        [provider downloadSuggestionsForSearchText:newSearchText success:^{
            if ([newSearchText isEqual:self.searchController.searchBar.searchField.text]) {
                weakSelf.suggestions = [provider suggestionsForSearchText:newSearchText];
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
	if (!section && !self.history.count)
		return nil;
	else if (section == 1 && !self.suggestions.count)
		return nil;

	DDGAutocompleteHeaderView *hv = [[DDGAutocompleteHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 25.0)];
	
	if (!section)
		hv.textLabel.text = @"Recent";
	else
		hv.textLabel.text = @"Suggestions";
	return hv;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (!section && self.history.count)
		return 25.0;
	if (section == 1 && self.suggestions.count)
		return 25.0;
	
	return 0.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
	{
        case 0:
            return self.history.count;
        case 1:
            return self.suggestions.count;
    }
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGAutocompleteCell *cell;
	BOOL lineHidden = NO;
    
    if(indexPath.section == 0) {
        cell = [tv dequeueReusableCellWithIdentifier:historyCellID];
        if(!cell)
            cell = [[DDGAutocompleteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:historyCellID];
        
        DDGHistoryItem *historyItem = [self.history objectAtIndex:indexPath.row];
        
        cell.textLabel.text = historyItem.title;
        
		lineHidden = (indexPath.row == self.history.count - 1) ? YES : NO;
    }
	else if(indexPath.section == 1)
	{
        cell = [tv dequeueReusableCellWithIdentifier:suggestionCellID];
        if(!cell) {
            cell = [[DDGAutocompleteCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:suggestionCellID];
            cell.imageView.image = [UIImage imageNamed:@"spacer64x64.png"];
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
        
        UIImage *image = nil;
        if([[suggestionItem objectForKey:@"image"] length]) {
            NSURL *URL = [NSURL URLWithString:[suggestionItem objectForKey:@"image"]];
            image = [self.imageCache objectForKey:URL];
		} else {
            image = [UIImage imageNamed:@"search_generic.png"];
        }
             
        cell.roundedImageView.image = image;
        
        if([suggestionItem objectForKey:@"calls"] && [[suggestionItem objectForKey:@"calls"] count])
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
	
    cell.showsSeparatorLine = !lineHidden;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!indexPath.section && self.history.count)
		return kCellHeightHistory+1;
	else if (indexPath.section == 1 && self.suggestions.count)
		return kCellHeightSuggestions+1;

	return 0.0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
	{
        DDGHistoryItem *item = [self.history objectAtIndex:indexPath.row];
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
        
        DDGAddressBarTextField *searchField = self.searchController.searchBar.searchField;
        NSString *searchText = searchField.text;
        NSArray *words = [searchText componentsSeparatedByString:@" "];
        if ([words count] == 1 && [[[words objectAtIndex:0] substringToIndex:1] isEqualToString:@"!"]) {
            searchField.text = [[suggestionItem objectForKey:@"phrase"] stringByAppendingString:@" "];
        } else {
            if([suggestionItem objectForKey:@"phrase"]) // if the server gave us bad data, phrase might be nil
                [self.historyProvider logSearchResultWithTitle:[suggestionItem objectForKey:@"phrase"]];            
            
            [self.searchController loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];
            [self.searchController dismissAutocomplete];
        }
    }
    
    [tv deselectRowAtIndexPath:indexPath animated:YES];
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
