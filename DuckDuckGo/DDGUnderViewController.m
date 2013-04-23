//
//  DDGUnderViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import "DDGUnderViewController.h"
#import "ECSlidingViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGWebViewController.h"
#import "DDGHistoryProvider.h"
#import "DDGBookmarksViewController.h"
#import "DDGStoriesViewController.h"
#import "DDGDuckViewController.h"
#import "DDGUnderViewControllerCell.h"
#import "DDGHistoryItemCell.h"
#import "DDGStory.h"
#import "DDGStoryFeed.h"
#import "DDGHistoryItem.h"
#import "DDGPlusButton.h"
#import "DDGHistoryViewController.h"

NSString * const DDGViewControllerTypeTitleKey = @"title";
NSString * const DDGViewControllerTypeTypeKey = @"type";
NSString * const DDGViewControllerTypeControllerKey = @"viewController";
NSString * const DDGSavedViewLastSelectedTabIndex = @"saved tab index";

@interface DDGUnderViewController () <DDGTableViewAdditionalSectionsDelegate>
@property (nonatomic, strong) NSIndexPath *menuIndexPath;
@property (nonatomic, strong) NSArray *viewControllerTypes;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) DDGHistoryViewController *historyViewController;
@end

@implementation DDGUnderViewController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        self.managedObjectContext = moc;        
        [self setupViewControllerTypes];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    DDGHistoryViewController *historyViewController = [[DDGHistoryViewController alloc] initWithSearchHandler:self managedObjectContext:self.managedObjectContext  mode:DDGHistoryViewControllerModeUnder];
    historyViewController.additionalSectionsDelegate = self;
    
    historyViewController.view.frame = self.view.bounds;
    historyViewController.tableView.scrollsToTop = NO;
    historyViewController.overhangWidth = 74;
    
    [self.view addSubview:historyViewController.view];
    [self addChildViewController:historyViewController];
    
    self.historyViewController = historyViewController;
    
    [historyViewController didMoveToParentViewController:self];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (![self isViewLoaded] || nil == self.view.superview) {
        self.historyViewController = nil;
    }
}

- (void)setupViewControllerTypes {
    
    DDGViewControllerType selectedType = DDGViewControllerTypeHome;
    NSIndexPath *menuIndexPath = self.menuIndexPath;
    
    if (menuIndexPath.section == 0 && menuIndexPath.row < [self.viewControllerTypes count]) {
        selectedType = [[[self.viewControllerTypes objectAtIndex:menuIndexPath.row] valueForKey:DDGViewControllerTypeTypeKey] integerValue];
    }
    
    NSMutableArray *types = [NSMutableArray array];
    
    NSString *homeViewMode = [[NSUserDefaults standardUserDefaults] objectForKey:DDGSettingHomeView];
    
    if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeRecents]) {
        [types addObject:[@{DDGViewControllerTypeTitleKey : @"Home",
                          DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeHistory)
                          } mutableCopy]];
        
        [types addObject:[@{DDGViewControllerTypeTitleKey : @"Stories",
                          DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeStories)
                          } mutableCopy]];
    } else {
        [types addObject:[@{DDGViewControllerTypeTitleKey : @"Home",
                          DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeHome)
                          } mutableCopy]];
    }

    [types addObject:[@{DDGViewControllerTypeTitleKey : @"Saved",
                      DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeSaved)
                      } mutableCopy]];
    
    [types addObject:[@{DDGViewControllerTypeTitleKey : @"Settings",
                      DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeSettings)
                      } mutableCopy]];
    
    self.viewControllerTypes = types;
    
    for (NSDictionary *typeInfo in types) {
        if ([[typeInfo valueForKey:DDGViewControllerTypeTypeKey] integerValue] == selectedType) {
            self.menuIndexPath = [NSIndexPath indexPathForRow:[types indexOfObject:typeInfo] inSection:0];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupViewControllerTypes];
    
    NSString *homeViewMode = [[NSUserDefaults standardUserDefaults] objectForKey:DDGSettingHomeView];
    self.historyViewController.showsHistory = ![homeViewMode isEqualToString:DDGSettingHomeViewTypeRecents];
    [self.historyViewController.tableView reloadData];
}

-(void)configureViewController:(UIViewController *)viewController {
    [viewController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    viewController.view.layer.shadowOpacity = 0.75f;
    viewController.view.layer.shadowRadius = 10.0f;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

#pragma mark - DDGTableViewAdditionalSectionsDelegate

- (NSInteger)numberOfAdditionalSections {
    return 1;
}

#pragma mark - DDGSearchHandler

- (void)beginSearchInputWithString:(NSString *)string {
    UIViewController *topViewController = self.slidingViewController.topViewController;
    if ([topViewController isKindOfClass:[DDGSearchController class]]) {
        DDGSearchController *searchController = (DDGSearchController *)topViewController;
        DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
        [self.slidingViewController resetTopViewWithAnimations:nil onComplete:^{
            [searchField becomeFirstResponder];
            searchField.text = string;
            [searchController searchFieldDidChange:nil];
        }];
    } else {
        [self loadQueryOrURL:string];
    }
}

- (void)prepareForUserInput {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:webVC managedObjectContext:self.managedObjectContext];
    webVC.searchController = searchController;
    
    [searchController pushContentViewController:webVC animated:NO];
    searchController.state = DDGSearchControllerStateWeb;    
    
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = searchController;
    self.slidingViewController.topViewController.view.frame = frame;
    [self configureViewController:searchController];
    
    [searchController.searchBar.searchField becomeFirstResponder];
}

-(void)searchControllerLeftButtonPressed {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:webVC managedObjectContext:self.managedObjectContext];
    webVC.searchController = searchController;
    
    [searchController pushContentViewController:webVC animated:NO];
    searchController.state = DDGSearchControllerStateWeb;    
    
    [webVC loadStory:story readabilityMode:readabilityMode];
    self.menuIndexPath = nil;
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = searchController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self configureViewController:searchController];
        
        [self.slidingViewController resetTopView];
    }];
    
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:webVC managedObjectContext:self.managedObjectContext];
    webVC.searchController = searchController;
    
    [searchController pushContentViewController:webVC animated:NO];
    searchController.state = DDGSearchControllerStateWeb;    
    
    [webVC loadQueryOrURL:queryOrURL];
    self.menuIndexPath = nil;    
    
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        CGRect frame = self.slidingViewController.topViewController.view.frame;
        self.slidingViewController.topViewController = searchController;
        self.slidingViewController.topViewController.view.frame = frame;
        [self configureViewController:searchController];
        
        [self.slidingViewController resetTopView];
    }];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.viewControllerTypes.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cell";

    DDGUnderViewControllerCell *cell = (DDGUnderViewControllerCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        if (indexPath.section == 0)
            cell = [[DDGUnderViewControllerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    DDGUnderViewControllerCell *underCell = (DDGUnderViewControllerCell *)cell;
    DDGFixedSizeImageView *fixedSizeImageView = underCell.fixedSizeImageView;
    
    underCell.active = ([indexPath isEqual:self.menuIndexPath]);
    
	underCell.imageView.image = nil;
    underCell.imageView.highlightedImage = nil;
    underCell.overhangWidth = 74;
    
	UILabel *lbl = underCell.textLabel;
    if(indexPath.section == 0)
	{
        lbl.text = [[self.viewControllerTypes objectAtIndex:indexPath.row] objectForKey:DDGViewControllerTypeTitleKey];
        
        NSDictionary *typeInfo = [self.viewControllerTypes objectAtIndex:indexPath.row];
        DDGViewControllerType type = [[typeInfo objectForKey:DDGViewControllerTypeTypeKey] integerValue];
        
		switch (type)
		{
			case DDGViewControllerTypeHome:
			case DDGViewControllerTypeHistory:
			{
				fixedSizeImageView.image = [UIImage imageNamed:@"icon_home"];
                fixedSizeImageView.highlightedImage = [UIImage imageNamed:@"icon_home_selected"];
			}
				break;
			case DDGViewControllerTypeSaved:
			{
				fixedSizeImageView.image = [UIImage imageNamed:@"icon_saved-pages"];
                fixedSizeImageView.highlightedImage = [UIImage imageNamed:@"icon_saved-pages_selected"];
			}
				break;
			case DDGViewControllerTypeStories:
			{
				fixedSizeImageView.image = [UIImage imageNamed:@"icon_stories"];
                fixedSizeImageView.highlightedImage = [UIImage imageNamed:@"icon_stories_selected"];
			}
				break;
			case DDGViewControllerTypeSettings:
			{
				fixedSizeImageView.image = [UIImage imageNamed:@"icon_settings"];
                fixedSizeImageView.highlightedImage = [UIImage imageNamed:@"icon_settings_selected"];
			}
				break;
		}
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (section == 0 ? 0 : 23);
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 23)];
    [headerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_divider.png"]]];    
    
    return headerView;
}

#pragma mark - Table view delegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1 && ![[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
		return nil;
	
    DDGUnderViewControllerCell *oldMenuCell;
    oldMenuCell = (DDGUnderViewControllerCell *)[tableView cellForRowAtIndexPath:self.menuIndexPath];
    oldMenuCell.active = NO;
    
    DDGUnderViewControllerCell *newMenuCell;
    newMenuCell = (DDGUnderViewControllerCell *)[tableView cellForRowAtIndexPath:indexPath];
    newMenuCell.active = YES;
    
	return indexPath;
}

- (UIViewController *)viewControllerForType:(DDGViewControllerType)type {
    UIViewController *viewController = nil;
    
    switch (type) {
        case DDGViewControllerTypeSaved:
        {
            DDGBookmarksViewController *bookmarks = [[DDGBookmarksViewController alloc] initWithNibName:@"DDGBookmarksViewController" bundle:nil];
            bookmarks.title = NSLocalizedString(@"Saved Searches", @"View controller title: Saved Searches");
            
            DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:self managedObjectContext:self.managedObjectContext];
            searchController.state = DDGSearchControllerStateHome;
            searchController.shouldPushSearchHandlerEvents = YES;
            
            DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:searchController managedObjectContext:self.managedObjectContext];
            stories.savedStoriesOnly = YES;
            stories.title = NSLocalizedString(@"Saved Stories", @"View controller title: Saved Stories");
            
            DDGTabViewController *tabViewController = [[DDGTabViewController alloc] initWithViewControllers:@[bookmarks, stories]];            
            [searchController pushContentViewController:tabViewController animated:NO];            
            
            bookmarks.searchController = searchController;
            bookmarks.searchHandler = searchController;
            
            tabViewController.controlViewPosition = DDGTabViewControllerControlViewPositionBottom;
            tabViewController.controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
            tabViewController.controlView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"saved_header_background"]];
            [tabViewController.segmentedControl sizeToFit];

            CGRect controlBounds = tabViewController.controlView.bounds;
            CGSize segmentSize = tabViewController.segmentedControl.frame.size;
            segmentSize.width = controlBounds.size.width - 10.0;
            CGRect controlRect = CGRectMake(controlBounds.origin.x + ((controlBounds.size.width - segmentSize.width) / 2.0),
                                            controlBounds.origin.y + ((controlBounds.size.height - segmentSize.height) / 2.0),
                                            segmentSize.width,
                                            segmentSize.height);
            tabViewController.segmentedControl.frame = CGRectIntegral(controlRect);
            tabViewController.segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
            tabViewController.searchControllerBackButtonIconDDG = [UIImage imageNamed:@"button_menu_glyph_saved"];

            [tabViewController.controlView addSubview:tabViewController.segmentedControl];
            tabViewController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
            tabViewController.delegate = self;
            
            viewController = searchController;
        }
            
            break;
        case DDGViewControllerTypeHistory: {
            DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:self managedObjectContext:self.managedObjectContext];
            searchController.shouldPushSearchHandlerEvents = YES;
            searchController.state = DDGSearchControllerStateHome;
            DDGHistoryViewController *history = [[DDGHistoryViewController alloc] initWithSearchHandler:searchController managedObjectContext:self.managedObjectContext mode:DDGHistoryViewControllerModeNormal];
            [searchController pushContentViewController:history animated:NO];
            viewController = searchController;
        }
            break;
        case DDGViewControllerTypeStories: {
            DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:self managedObjectContext:self.managedObjectContext];
            searchController.shouldPushSearchHandlerEvents = YES;
            searchController.state = DDGSearchControllerStateHome;
            DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:searchController managedObjectContext:self.managedObjectContext];
            stories.searchControllerBackButtonIconDDG = [UIImage imageNamed:@"button_menu_glyph_stories"];
            [searchController pushContentViewController:stories animated:NO];
            viewController = searchController;
        }
            break;
        case DDGViewControllerTypeSettings: {
            
            DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:self managedObjectContext:self.managedObjectContext];
            searchController.state = DDGSearchControllerStateHome;
            DDGSettingsViewController *settings = [[DDGSettingsViewController alloc] initWithDefaults];
            settings.managedObjectContext = self.managedObjectContext;
            [searchController pushContentViewController:settings animated:NO];
            viewController = searchController;
            break;
        }
        case DDGViewControllerTypeHome:
        {
            DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:self managedObjectContext:self.managedObjectContext];
            searchController.shouldPushSearchHandlerEvents = YES;
//            if ([[DDGCache objectForKey:DDGSettingHomeView inCache:DDGSettingsCacheName] isEqual:DDGSettingHomeViewTypeDuck]) {
//                searchController.contentController = [DDGDuckViewController duckViewController];
//            } else {
            DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:searchController managedObjectContext:self.managedObjectContext];
            stories.searchControllerBackButtonIconDDG = [UIImage imageNamed:@"button_menu_glyph_home"];
            [searchController pushContentViewController:stories animated:NO];
//            }
            searchController.state = DDGSearchControllerStateHome;
            viewController = searchController;
        }
        default:
            break;
    }
    
    return viewController;
}

- (UIViewController *)viewControllerForIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController = nil;
    
    if(indexPath.section == 0)
    {
        NSDictionary *typeInfo = [self.viewControllerTypes objectAtIndex:indexPath.row];
        viewController = [typeInfo objectForKey:DDGViewControllerTypeControllerKey];
        
        if (nil == viewController) {
            DDGViewControllerType type = [[typeInfo objectForKey:DDGViewControllerTypeTypeKey] integerValue];
            viewController = [self viewControllerForType:type];            
        }
    }
    
    return viewController;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        
        self.menuIndexPath = indexPath;
        
        if(indexPath.section == 0)
		{
            UIViewController *newTopViewController = [self viewControllerForIndexPath:indexPath];
            
            if (nil != newTopViewController) {
                CGRect frame = self.slidingViewController.topViewController.view.frame;
                self.slidingViewController.topViewController = newTopViewController;
                self.slidingViewController.topViewController.view.frame = frame;
                [self.slidingViewController resetTopView];
                
                [self configureViewController:newTopViewController];                
            }
        }
    }];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	CGSize sz = [[UIScreen mainScreen] bounds].size;
	CGFloat width;
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
		width = sz.width;
	else
		width = sz.height;
	
    [self.slidingViewController setAnchorRightRevealAmount:width - 65.0];
}

#pragma mark - DDGTabViewControllerDelegate

- (void)tabViewController:(DDGTabViewController *)tabViewController didSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)tabIndex {
    [[NSUserDefaults standardUserDefaults] setInteger:tabIndex forKey:DDGSavedViewLastSelectedTabIndex];
}

@end
