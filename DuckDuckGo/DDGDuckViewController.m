//
//  DDGDuckViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import "DDGAddressBarTextField.h"
#import "DDGDuckViewController.h"
#import "DDGSearchBar.h"
#import "DDGSearchController.h"
#import "DDGAutocompleteTableView.h"
#import "DDGSearchSuggestionsProvider.h"
#import "DDGAutocompleteCell.h"
#import "DDGMenuHistoryItemCell.h"
#import "UIColor+DDG.h"
#import "AFNetworking.h"

#import "DDGBookmarksViewController.h"
#import "DDGTier2ViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGPlusButton.h"
#import "DDGAutocompleteHeaderView.h"
#import "DDGBookmarksProvider.h"
#import "DDGUtility.h"

#define MAX_FAVORITE_SUGGESTIONS 5

@interface DDGDuckViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, DDGHistoryItemCellDelegate>

@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;

@property (nonatomic, copy) NSArray* history;
@property (nonatomic, copy) NSArray* favorites;

@property (nonatomic, copy) NSArray *suggestions;
@property (nonatomic, strong) NSOperationQueue *imageRequestQueue;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSString* filterString;
@end

@implementation DDGDuckViewController

// static NSString *bookmarksCellID = @"BCell";
static NSString *suggestionCellID = @"SCell";
static NSString *historyCellID = @"HCell";

#define kCellHeightHistory			44.0
#define kCellHeightSuggestions		66.0

- (instancetype)initWithSearchController:(DDGSearchController *)searchController
                    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self) {
        self.searchController = searchController;
        self.managedObjectContext = managedObjectContext;
        self.historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
        self.filterString = @"";
    }
    return self;
}

- (void)dealloc
{
    [self.imageRequestQueue cancelAllOperations];
    self.imageRequestQueue = nil;
}

-(void)reloadHistory
{
    // load our new best cached result, and download new autocomplete suggestions.
    CGRect f = self.view.frame;
    DLog(@"loading history for frame %@", NSStringFromCGRect(f));
    NSInteger maxItems = f.size.height > 600 ? 5 : 3;
    self.history = [self.historyProvider pastHistoryItemsForPrefix:self.filterString withMaximumCount:maxItems];
    DLog(@"loaded history with prefix/substring: %@ and got %li results", self.filterString, self.history.count);
//
//    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGHistoryItem entityName]];
//    NSFetchedResultsController* historyController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
//                                                                                        managedObjectContext:self.managedObjectContext
//                                                                                          sectionNameKeyPath:@"section"
//                                                                                                   cacheName:nil];
//    historyController.delegate = self;
//    [request setPredicate:[NSPredicate predicateWithFormat:@"section == %@", DDGHistoryItemSectionNameSearches]];
//    NSString* filter = self.filterString;
//    if(filter.length>0) {
//        [request setPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS %@", self.filterString]];
//    }
//    
//    NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO];
//    [request setSortDescriptors:@[timeSort]];
//    
//    NSError *error = nil;
//    if (![historyController performFetch:&error]) {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//    }
//    
//    NSArray* fetchedHistory = historyController.fetchedObjects;
//    if(fetchedHistory.count > MAX_HISTORY_SUGGESTIONS) {
//        self.history = [fetchedHistory objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, MAX_HISTORY_SUGGESTIONS)]];
//    } else {
//        self.history = historyController.fetchedObjects;
//    }
}


-(void)reloadFavorites
{
    NSMutableArray* fetchedBookmarks = [[NSMutableArray alloc] initWithArray:[[[DDGBookmarksProvider sharedProvider].bookmarks reverseObjectEnumerator] allObjects]];
    NSInteger unfilteredBookmarkCount = fetchedBookmarks.count;
    NSString* filter = self.filterString;
    if(filter.length>0) {
        for(NSInteger i=fetchedBookmarks.count-1; i>=0; i--) {
            if( ! [fetchedBookmarks[i][@"title"] containsString:filter]) {
                [fetchedBookmarks removeObjectAtIndex:i];
            }
        }
    }
    if(fetchedBookmarks.count >= MAX_FAVORITE_SUGGESTIONS) {
        self.favorites = [fetchedBookmarks objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, MAX_FAVORITE_SUGGESTIONS)]];
    } else {
        self.favorites = fetchedBookmarks;
    }
    DLog(@"limited favorites to %lu  (was %li)", (unsigned long)self.favorites.count, (long)unfilteredBookmarkCount);
}

-(void)reloadAll
{
    NSString* searchStr = self.searchController.searchBar.searchField.text;
    self.filterString = searchStr==nil ? @"" : searchStr;
    [self reloadHistory];
    [self reloadFavorites];
    [self reloadSuggestions];
    [self.tableView reloadData];
}

-(void)reloadSuggestions
{
    NSString* searchText = self.filterString;
    DDGSearchSuggestionsProvider *provider = [DDGSearchSuggestionsProvider sharedProvider];
    __weak DDGDuckViewController *weakSelf = self;
    
    [provider downloadSuggestionsForSearchText:searchText success:^{
        if ([self.filterString isEqual:searchText]) {
            weakSelf.suggestions = [provider suggestionsForSearchText:self.filterString];
            [self.tableView reloadData];
        }
    }];
}


-(void)viewDidLoad {
    [super viewDidLoad];
    
    // use our custom table view class
    self.tableView = [[DDGAutocompleteTableView alloc] initWithFrame:self.tableView.frame
                                                               style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.clearsSelectionOnViewWillAppear = FALSE;
    self.tableView.backgroundColor = [UIColor duckStoriesBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.scrollsToTop = NO;
    
    self.imageCache = [NSCache new];
    
    //[self.view addSubview:self.tableView];
    
    [self searchFieldDidChange:@""];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 4;
    self.imageRequestQueue = queue;
    
    [self reloadAll];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.imageCache removeAllObjects];
    
    [self.imageRequestQueue cancelAllOperations];
    self.imageRequestQueue = nil;
}


-(void)plusButtonWasPushed:(DDGMenuHistoryItemCell*)menuCell
{
    DDGSearchController *searchController = [self searchControllerDDG];
    if (searchController) {
        DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
        [searchField becomeFirstResponder];
        if(menuCell.historyItem) {
            searchField.text = menuCell.historyItem.title;
        } else if(menuCell.bookmarkItem) {
            searchField.text = menuCell.bookmarkItem[@"title"];
        }
        [searchController searchFieldDidChange:nil];
    }
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
                __weak DDGDuckViewController *weakSelf = self;
                void (^success)(UIImage *image) = ^(UIImage *image) {
                    if(image==nil || URL==nil) return; // avoid crash if image is nil (it happened!)
                    [weakSelf.imageCache setObject:image forKey:URL];
                    NSUInteger row = [weakSelf.suggestions indexOfObject:suggestionItem];
                    if (row != NSNotFound) {
                        DDGAutocompleteCell *cell = (DDGAutocompleteCell *)[weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
                        [cell.imageView setImage:image];
                        [cell setNeedsLayout];
                    }
                };
                
                AFImageRequestOperation *imageOperation = [AFImageRequestOperation imageRequestOperationWithRequest:[DDGUtility requestWithURL:URL]
                                                                                                            success:success];
                [self.imageRequestQueue addOperation:imageOperation];
            }
        }
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    DLog(@"rotated, baby");
    [self reloadHistory];
    [self.tableView reloadData];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) {
        return TRUE;
    }
    return FALSE;
}

-(DDGSearchController *)searchController {
    return (DDGSearchController *)self.navigationController.parentViewController;
}

- (void)searchFieldDidChange:(id)sender
{
    [self reloadAll];
    
    /* Disabled as per https://github.com/duckduckgo/ios/issues/25
     if([newSearchText isEqualToString:[self.searchController validURLStringFromString:newSearchText]]) {
     // we're definitely editing a URL, don't bother with autocomplete.
     return;
     }
     */
}

-(void)tableViewBackgroundTouched {
    [self.searchController dismissAutocomplete];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
//    NSInteger numHistoryResults = self.historyController.fetchedObjects.count;
//    NSInteger numFavResults = self.favoritesController.fetchedObjects.count;
//    NSInteger acResults = self.suggestions.count;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case 0:
            if(self.history.count<=0) return nil;
            break;
        case 1:
            if(self.favorites.count<=0) return nil;
            break;
        case 2:
            if(self.suggestions.count<=0) return nil;
            break;
    }
    
    DDGAutocompleteHeaderView *hv = [[DDGAutocompleteHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 25.0)];
    hv.textLabel.text = @"";
    return hv;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case 0: return self.history.count<=0 ? 0 : 25.0;
        case 1: return self.favorites.count<=0 ? 0 : 25.0;
        case 2: return self.suggestions.count<=0 ? 0 : 25.0;
        default: return 0.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return self.history.count;
        case 1: return self.favorites.count;
        case 2: return self.suggestions.count;
    }
    return 0;

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 0: {
            DDGMenuHistoryItemCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
            if(cell==nil) {
                cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGMenuHistoryItemCell"];
            }
            cell.historyItem = self.history[indexPath.row];
            cell.historyDelegate = self;
            cell.isLastItem = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
            return cell;
        }
        case 1: {
            NSDictionary *bookmark = self.favorites[indexPath.row];
            DDGMenuHistoryItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
            if(cell==nil) {
                cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGMenuHistoryItemCell"];
            }
            cell.bookmarkItem = bookmark;
            cell.historyDelegate = self;
            cell.isLastItem = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
            return cell;
        }
        default: {
            BOOL lineHidden = NO;
            DDGAutocompleteCell *cell = [tableView dequeueReusableCellWithIdentifier:suggestionCellID];
            if (!cell) {
                cell = [[DDGAutocompleteCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:suggestionCellID];
            }
            [cell setAdorned:NO];
            
            lineHidden = (indexPath.row == self.suggestions.count - 1) ? YES : NO;
            
            NSArray *suggestions = self.suggestions;
            
            // the tableview sometimes requests rows that don't exist. in this case the table's reloading anyway so just return whatever and don't crash.
            NSDictionary *suggestionItem;
            if(indexPath.row < suggestions.count)
                suggestionItem = [suggestions objectAtIndex:indexPath.row];
            
            cell.textLabel.text = [suggestionItem objectForKey:@"phrase"];
            cell.detailTextLabel.text = [suggestionItem objectForKey:@"snippet"];
            cell.showsSeparatorLine = !lineHidden;
            
            [cell addTarget:self action:@selector(plus:) forControlEvents:UIControlEventTouchUpInside];
            
            if([[suggestionItem objectForKey:@"image"] length]) {
                NSURL *URL = [NSURL URLWithString:[suggestionItem objectForKey:@"image"]];
                UIImage *image = [self.imageCache objectForKey:URL];
                [cell setAdorned:YES];
                //            cell.roundedImageView.image = image;
                //            cell.imageView.image = [UIImage imageNamed:@"spacer64x64.png"];
                [cell.imageView setImage:image];
            }
            
            if([suggestionItem objectForKey:@"calls"] && [[suggestionItem objectForKey:@"calls"] count]) {
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case 2: {
            NSDictionary* suggestion = self.suggestions[indexPath.row];
            if (suggestion[@"image"] && [suggestion[@"image"] length] > 0) {
                return 60.0f;
            } else {
                return 44.0f;
            }
        }
        case 0:
        case 1:
        default:
            return 44.0f;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGSearchController *searchController = [self searchControllerDDG];
    if(indexPath.section == 0) {  // a recent item was tapped
        DDGHistoryItem *item = self.history[indexPath.row];
        [self.historyProvider relogHistoryItem:item];
        DDGStory *story = item.story;
        NSInteger readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
        if (item.story) {
            [searchController loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
        } else {
            [searchController loadQueryOrURL:item.title];
        }
        
        [searchController dismissAutocomplete];
    } else if(indexPath.section == 1) {  // a favorite item was tapped
        NSDictionary* bookmark = self.favorites[indexPath.row];
        [searchController loadQueryOrURL:[bookmark objectForKey:@"url"]];
        
    } else if (indexPath.section == 2) { // a suggestion was tapped
        NSDictionary* suggestionItem = self.suggestions[indexPath.row];
        DDGAddressBarTextField *searchField = self.searchController.searchBar.searchField;
        NSString *searchText = searchField.text;
        NSArray *words = [searchText componentsSeparatedByString:@" "];
        
        BOOL isBang = NO;
        if ([words count] == 1 && [[words firstObject] length] > 0) {
            isBang = [[[words firstObject] substringToIndex:1] isEqualToString:@"!"];
        }
        if (isBang) {
            searchField.text = [[suggestionItem objectForKey:@"phrase"] stringByAppendingString:@" "];
        } else {
            if([suggestionItem objectForKey:@"phrase"]) {// if the server gave us bad data, phrase might be nil
                [self.historyProvider logSearchResultWithTitle:[suggestionItem objectForKey:@"phrase"]];
            }
            
            [searchController loadQueryOrURL:[suggestionItem objectForKey:@"phrase"]];
            [searchController dismissAutocomplete];
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

- (void)updateContainerHeightConstraint:(BOOL)keyboardShowing
{
    [self.containerViewHeightConstraint setConstant:keyboardShowing ? 170.0f : 230.0f];
}


@end
















