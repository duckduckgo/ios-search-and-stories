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
#import "DDGSearchSuggestionsProvider.h"
#import "DDGAutocompleteCell.h"
#import "DDGMenuHistoryItemCell.h"
#import "AFNetworking.h"

#import "DDGBookmarksViewController.h"
#import "DDGTier2ViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGPlusButton.h"
#import "DDGAutocompleteHeaderView.h"
#import "DDGBookmarksProvider.h"
#import "DDGUtility.h"
#import "DuckDuckGo-Swift.h"

#define MAX_FAVORITE_SUGGESTIONS 5

#define ONBOARDING_SECTION 0
#define RECENTS_SECTION 1
#define FAVORITES_SECTION 2
#define SUGGESTION_SECTION 3

@interface DDGDuckViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, DDGHistoryItemCellDelegate> {
    BOOL _underPopoverMode;
}

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, weak) DDGSearchController *searchController;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;

@property (nonatomic, copy) NSArray* history;
@property (nonatomic, copy) NSArray* favorites;

@property (nonatomic, copy) NSArray *suggestions;
@property (nonatomic, strong) NSOperationQueue *imageRequestQueue;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSString* filterString;
@property (nonatomic, strong) MiniOnboardingViewController* onboarding;
@end

@implementation DDGDuckViewController

// static NSString *bookmarksCellID = @"BCell";
static NSString *suggestionCellID = @"SCell";
static NSString *historyCellID = @"HCell";

NSString* const DDGOnboardingBannerTableCellIdentifier = @"MiniOnboardingTableCell";

#define kCellHeightHistory			44.0
#define kCellHeightSuggestions		66.0

- (instancetype)initWithSearchController:(DDGSearchController *)searchController
                    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if(self) {
        self.searchController = searchController;
        self.managedObjectContext = managedObjectContext;
        self.historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
        self.filterString = @"";
        self.underPopoverMode = FALSE;
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
    NSUInteger maxHistory = self.popoverMode ? 5 : (self.view.frame.size.height > 600 ? 5 : 3);
    self.history = [self.historyProvider pastHistoryItemsForPrefix:self.filterString
                                                    onlyQueries:TRUE
                                                  withMaximumCount:maxHistory];
}


-(void)reloadFavorites
{
    NSMutableArray* fetchedBookmarks = [[NSMutableArray alloc] initWithArray:[[[DDGBookmarksProvider sharedProvider].bookmarks reverseObjectEnumerator] allObjects]];
    NSString* filter = self.filterString;
    if(filter.length>0) {
        for(NSInteger i=fetchedBookmarks.count-1; i>=0; i--) {
            if( ! [fetchedBookmarks[i][@"title"] containsString:filter]) {
                [fetchedBookmarks removeObjectAtIndex:i];
            }
        }
    }
//    if(fetchedBookmarks.count >= MAX_FAVORITE_SUGGESTIONS) {
//        self.favorites = [fetchedBookmarks objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, MAX_FAVORITE_SUGGESTIONS)]];
//    } else {
        self.favorites = fetchedBookmarks;
//    }
}

-(void)reloadAll
{
    NSString* searchStr = self.searchController.searchBar.searchField.text;
    if([DDGUtility looksLikeURL:searchStr]) {
        searchStr = @"";
    }
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.filterString isEqual:searchText]) {
                weakSelf.suggestions = [provider suggestionsForSearchText:self.filterString];
            }
        });
    }];
}


-(void)viewDidLoad {
    [super viewDidLoad];
    
    // use our custom table view class
    CGRect viewFrame = self.view.frame;
    viewFrame.origin = CGPointMake(0, 0);
    self.tableView = [[UITableView alloc] initWithFrame:viewFrame style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.tableView registerClass:OnboardingMiniTableViewCell.class
           forCellReuseIdentifier:DDGOnboardingBannerTableCellIdentifier];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.sectionFooterHeight = 0.01f;
    self.tableView.backgroundColor = [UIColor duckStoriesBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor duckTableSeparator];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    
    // show the mini banner and register for updates to further show or hide it
    [self updateOnboardingState];
    
    //self.view = self.tableView;
    if(self.popoverMode) {
        self.tableView.layer.cornerRadius = 4.0;
    }

    [self.view addSubview:self.tableView];
    self.imageCache = [NSCache new];
    
    //[self searchFieldDidChange:@""];
}

-(void)updateOnboardingState {
    BOOL showIt = [NSUserDefaults.standardUserDefaults boolForKey:kDDGMiniOnboardingName defaultValue:TRUE];
    // hide the banner if we're on an iPad or landscape.  In other words, if the width is not "compact"
    showIt &= self.onboardingShouldBeVisible;
    self.showsOnboarding = showIt;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.onboarding viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 4;
    self.imageRequestQueue = queue;
    
    [self reloadAll];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.underPopoverMode) {
        [self.searchControllerDDG.searchBar.searchField becomeFirstResponder];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.imageCache removeAllObjects];
    
    [self.imageRequestQueue cancelAllOperations];
    self.imageRequestQueue = nil;
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateOnboardingState];
}


-(void)plusButtonWasPushed:(DDGMenuHistoryItemCell*)menuCell
{
    DDGSearchController *searchController = [self searchControllerDDG];
    if (searchController) {
        DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
        [searchField becomeFirstResponder];
        if(menuCell.historyItem.title) {
            searchField.text = menuCell.historyItem.title;
        } else if(menuCell.bookmarkItem) {
            searchField.text = menuCell.bookmarkItem[@"title"];
        } else if(menuCell.suggestionItem) {
            searchField.text = [menuCell.suggestionItem objectForKey:@"phrase"];
        }
        [searchController searchFieldDidChange:nil];
    }
}

-(BOOL)underPopoverMode {
    return _underPopoverMode;
}

-(void)setUnderPopoverMode:(BOOL)underPopoverMode
{
    _underPopoverMode = underPopoverMode;
    [self.tableView reloadData];
}


-(BOOL)onboardingShouldBeVisible {
    return self.view.frame.size.width <= 480;
}

-(BOOL)showsOnboarding {
    return self.onboarding!=nil;
}

-(void)setShowsOnboarding:(BOOL)showOnboarding {
    if(showOnboarding==self.showsOnboarding) return;
    
    if(showOnboarding) {
        
        self.onboarding = [MiniOnboardingViewController loadFromStoryboard];
        self.onboarding.bottomBorderHidden = TRUE;
        self.onboarding.dismissHandler = ^{
            [NSUserDefaults.standardUserDefaults setBool:FALSE forKey:kDDGMiniOnboardingName];
            [NSUserDefaults.standardUserDefaults synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDDGMiniOnboardingName object:nil];
        };
        [self addChildViewController:self.onboarding];
        [self.tableView reloadData];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateOnboardingState)
                                                     name:kDDGMiniOnboardingName object:nil];
    } else {
        self.onboarding.dismissHandler = nil;
        [self.onboarding removeFromParentViewController];
        self.onboarding = nil;
        [self.tableView reloadData];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDDGMiniOnboardingName object:nil];
    }
}



- (void)setSuggestions:(NSArray *)suggestions {
    if (suggestions == _suggestions)
        return;
    if(suggestions.count==0 && _suggestions.count==0)
        return;
    
    [self.imageRequestQueue cancelAllOperations];
    
    _suggestions = suggestions;//[suggestions copy];
    [self.tableView reloadData];
    
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
//    [self reloadHistory]; // reload the history because if we're on a shorter screen we'll show fewer items
//    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

//-(DDGSearchController *)searchController {
//    return (DDGSearchController *)self.navigationController.parentViewController;
//}

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

-(void)duckGoToTopLevel
{
    if(self.navigationController.viewControllers.count>1) {
        [self.navigationController popToRootViewControllerAnimated:TRUE];
    }
    [self.tableView scrollRectToVisible:CGRectZero animated:TRUE];
    [self.searchController.searchBar.searchField becomeFirstResponder];
}


#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self.underPopoverMode) return 0;
    return 4;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case ONBOARDING_SECTION:
            return nil;
        case RECENTS_SECTION:
            if(self.history.count<=0) return nil;
            break;
        case FAVORITES_SECTION:
            if(self.favorites.count<=0) return nil;
            break;
        case SUGGESTION_SECTION:
            if(self.suggestions.count<=0) return nil;
            break;
    }
    
    DDGAutocompleteHeaderView *hv = [[DDGAutocompleteHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 25.0)];
    hv.textLabel.text = @"";
    return hv;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat headerHeight = 0.01f;
    NSUInteger historyCount = self.history.count;
    NSUInteger favCount = self.favorites.count;
    NSUInteger suggestionCount = self.suggestions.count;

    if(self.popoverMode) {
        // if we're in popover mode, we only show a section header if there is a non-empty section above us
        switch(section) {
            case ONBOARDING_SECTION:
                headerHeight = 0.01; // the onboarding section never has another section above it
                break;
            case RECENTS_SECTION:
                headerHeight = 0.01; // the recents/history section never has another section above it
                break;
            case FAVORITES_SECTION:
                headerHeight = favCount<=0 ? 0.01 : (historyCount>0 ? 25.0 : 0.01f);
                break;
            case SUGGESTION_SECTION:
                headerHeight = suggestionCount<=0 ? 0.01 : (historyCount+favCount>0 ? 25.0 : 0.01f);
                break;
        }
    } else {
        switch(section) {
            case ONBOARDING_SECTION:
                headerHeight = 0.01; // no header ever for the onboarding section
                break;
            case RECENTS_SECTION:
                headerHeight = historyCount<=0 ? 0.01 : ((self.showsOnboarding && self.onboardingShouldBeVisible) ? 0.01 : 25.0); // only show header if the onboarding bottom border isn't visible
                break;
            case FAVORITES_SECTION:
                headerHeight = favCount<=0 ? 0.01 : 25.0;
                break;
            case SUGGESTION_SECTION:
                headerHeight = suggestionCount<=0 ? 0.01 : 25.0;
                break;
        }
    }
    return headerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.underPopoverMode) return 0;
    switch (section) {
        case ONBOARDING_SECTION: {
            if(self.showsOnboarding && self.suggestions.count + self.history.count + self.favorites.count <= 0) return 1; // don't show onboarding row if there are any values in the other sections
            else return 0;
        }
        case RECENTS_SECTION: return self.history.count;
        case FAVORITES_SECTION: return self.favorites.count;
        case SUGGESTION_SECTION: return self.suggestions.count;
    }
    return 0;

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case ONBOARDING_SECTION: {
            OnboardingMiniTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:DDGOnboardingBannerTableCellIdentifier forIndexPath:indexPath];
            cell.onboarder = self.onboarding;
            return cell;
        }
        case RECENTS_SECTION: {
            DDGMenuHistoryItemCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
            if(cell==nil) {
                cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGMenuHistoryItemCell"];
            }
            cell.historyItem = self.history[indexPath.row];
            cell.historyDelegate = self;
            cell.isLastItem = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
            return cell;
        }
        case FAVORITES_SECTION: {
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
        case SUGGESTION_SECTION:
        default: {
            NSArray *suggestions = self.suggestions;
            NSDictionary *suggestionItem = indexPath.row < suggestions.count ? [suggestions objectAtIndex:indexPath.row] : nil;
            DDGMenuHistoryItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DDGAutocompletionCell"];
            if(cell==nil) {
                cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGAutocompletionCell"];
                [cell configureForAutocompletion];
            }
            
            cell.suggestionItem = suggestionItem;
            cell.historyDelegate = self;
            cell.isLastItem = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
            
            NSString* imgURLString = [suggestionItem objectForKey:@"image"];
            NSURL* URL = [imgURLString length] ? [NSURL URLWithString:imgURLString] : nil;
            UIImage* icon = URL ? [self.imageCache objectForKey:URL] : nil;
            if(icon) {
                [cell setIcon:icon];
            } else if(URL) {
                // the autocomplete icon wasn't found, so let's load it and push it into the cell
                __weak DDGDuckViewController *weakSelf = self;
                void (^success)(UIImage *image) = ^(UIImage *image) {
                    if(image==nil || URL==nil) return; // avoid crash if image is nil (it happened!)
                    
                    // resize the image appropriately
                    CGSize newSize = CGSizeMake(16, 16);
                    float widthRatio = newSize.width/image.size.width;
                    float heightRatio = newSize.height/image.size.height;
                    
                    if(widthRatio > heightRatio) {
                        newSize = CGSizeMake(image.size.width*heightRatio, image.size.height*heightRatio);
                    } else {
                        newSize = CGSizeMake(image.size.width*widthRatio, image.size.height*widthRatio);
                    }
                    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
                    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
                    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    image = newImage;
                    
                    [weakSelf.imageCache setObject:image forKey:URL];
                    dispatch_async(dispatch_get_main_queue(), ^{ // update the cell with the image icon on the main thread
                        NSUInteger row = [weakSelf.suggestions indexOfObject:suggestionItem];
                        if (row == indexPath.row) { // make sure the cell is still at the same location and hasn't been replaced
                            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        }
                    });
                };
                AFImageRequestOperation *imageOperation = [AFImageRequestOperation imageRequestOperationWithRequest:[DDGUtility requestWithURL:URL]
                                                                                                            success:success];
                [self.imageRequestQueue addOperation:imageOperation];
            }
            
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case ONBOARDING_SECTION: {
            CGFloat onboardHeight = 0;
            if(self.showsOnboarding) {
                onboardHeight = self.view.frame.size.width <= 480 ? 200 : 155;
            }
            return onboardHeight;
        }
        case SUGGESTION_SECTION: {
            return 50.0f;
        }
        case RECENTS_SECTION:
        case FAVORITES_SECTION:
        default:
            return 44.0f;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGSearchController *searchController = [self searchControllerDDG];
    if(indexPath.section == RECENTS_SECTION) {  // a recent item was tapped
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
    } else if(indexPath.section == FAVORITES_SECTION) {  // a favorite item was tapped
        NSDictionary* bookmark = self.favorites[indexPath.row];
        [searchController loadQueryOrURL:[bookmark objectForKey:@"url"]];
        [searchController dismissAutocomplete];
    } else if (indexPath.section == SUGGESTION_SECTION) { // a suggestion was tapped
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

#pragma mark == Support For Keyboard ==
- (void)setBottomPaddingBy:(CGFloat)paddingHeight {
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, paddingHeight, 0)];
}

@end
















