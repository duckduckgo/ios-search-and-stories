//
//  DDGHomeViewController.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 26/06/2015.
//
//

#import "DDGHomeViewController.h"

#import "DDGSearchController.h"
#import "DDGStoriesViewController.h"
#import "DDGHistoryViewController.h"
#import "DDGAppDelegate.h"
#import "DDGWebViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGDuckViewController.h"
#import "DDGBookmarksViewController.h"
#import "UIColor+DDG.h"

@interface DDGHomeViewController ()
@property (nonatomic, strong) IBOutlet UIView* tabContentView;
@property (nonatomic, strong) UITabBarController* tabController;

@property (nonatomic, strong) DDGSearchController* storiesTopController;
@property (nonatomic, strong) DDGSearchController* settingsTopController;
@property (nonatomic, strong) DDGSearchController* searchTopController;
@property (nonatomic, strong) DDGSearchController* favoritesTopController;
@property (nonatomic, strong) DDGSearchController* recentsTopController;

@property (nonatomic, strong) DDGStoriesViewController* storiesController;
@property (nonatomic, strong) DDGSettingsViewController* settingsController;
@property (nonatomic, strong) DDGDuckViewController* searchController;
@property (nonatomic, strong) DDGTabViewController* favoritesTabViewController;
@property (nonatomic, strong) DDGTabViewController* recentsController;

@property (nonatomic, strong) IBOutlet UIView* toolbarContainer;

@property (nonatomic, strong) IBOutlet UIView* searchButtonBar;
@property (nonatomic, strong) IBOutlet UIButton* storiesTabButton;
@property (nonatomic, strong) IBOutlet UIButton* settingsTabButton;
@property (nonatomic, strong) IBOutlet UIButton* searchTabButton;
@property (nonatomic, strong) IBOutlet UIButton* favoritesTabButton;
@property (nonatomic, strong) IBOutlet UIButton* recentsTabButton;

@property (nonatomic, strong) NSArray* tabButtons;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topAlignmentConstraint;

@property (nonatomic, strong) IBOutlet UIView* alternateToolbarContainer;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* alternateToolbarBottom;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* tabBarTopBorderConstraint;
@end

@implementation DDGHomeViewController


+(DDGHomeViewController*)newHomeController {
  return [[DDGHomeViewController alloc] initWithNibName:@"DDGHomeViewController" bundle:nil];
}

-(BOOL)hideTabBar {
    return self.searchButtonBar.hidden;
}

-(void)setAlternateButtonBar:(UIView *)alternateButtonBar {
    if(alternateButtonBar!=_alternateButtonBar) {
        if(alternateButtonBar) {
            [self.alternateToolbarContainer addSubview:alternateButtonBar];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeLeading
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeLeading
                                                                                      multiplier:1 constant:0]];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeTrailing
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeTrailing
                                                                                      multiplier:1 constant:0]];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeTop
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeTop
                                                                                      multiplier:1 constant:0]];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeBottom
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeBottom
                                                                                      multiplier:1 constant:0]];
            self.alternateToolbarBottom.constant = 0;
            [self.alternateToolbarContainer setNeedsUpdateConstraints];
        } else {
            // show the default home button bar
            self.alternateToolbarBottom.constant = 50;
            [_alternateButtonBar removeFromSuperview];
            [self.alternateToolbarContainer removeConstraints:self.alternateToolbarContainer.constraints];
        }
    }
    _alternateButtonBar = alternateButtonBar;
    //    self.searchButtonBar.hidden = TRUE;
}

-(IBAction)showRecents {
    self.tabController.selectedViewController = self.recentsTopController;
    [self setSelectedButton:self.recentsTabButton];
}

-(IBAction)showFavorites {
    self.tabController.selectedViewController = self.favoritesTopController;
    [self setSelectedButton:self.favoritesTabButton];
}

-(IBAction)showStories {
    self.tabController.selectedViewController = self.storiesTopController;
    [self setSelectedButton:self.storiesTabButton];
}

-(IBAction)showDuck {
    self.tabController.selectedViewController = self.searchTopController;
    [self setSelectedButton:self.searchTabButton];
}

-(IBAction)showSettings {
    self.tabController.selectedViewController = self.settingsTopController;
    [self setSelectedButton:self.settingsTabButton];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarTopBorderConstraint.constant = 0.5f;
    self.tabButtons = @[self.searchTabButton, self.storiesTabButton, self.favoritesTabButton, self.recentsTabButton, self.settingsTabButton ];
    
    self.tabController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    self.tabController.delegate = self;
    [self addChildViewController:self.tabController];
    self.tabController.view.frame = self.tabContentView.frame;
    [self.tabContentView addSubview:self.tabController.view];
    [self.tabController didMoveToParentViewController:self];
    self.tabController.tabBar.hidden = TRUE;
    
    self.view.backgroundColor = [UIColor duckSearchBarBackground];
    
    NSMutableArray* controllers = [NSMutableArray new];
    
    { // configure the search view controller
        self.searchTopController = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                       homeController:self
                                                                 managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.searchTopController.state = DDGSearchControllerStateHome;
        self.searchTopController.shouldPushSearchHandlerEvents = YES;
        self.searchController = [[DDGDuckViewController alloc] initWithSearchController:self.searchTopController
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        [self.searchTopController pushContentViewController:self.searchController animated:NO];
        self.searchTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                            image:[[UIImage imageNamed:@"Tab-Search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                    selectedImage:[[UIImage imageNamed:@"Tab-Search-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:self.searchTopController];
    }
    
    { // configure the stories view controller
        self.storiesTopController = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                        homeController:self
                                                                  managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.storiesTopController.shouldPushSearchHandlerEvents = YES;
        self.storiesController = [[DDGStoriesViewController alloc] initWithSearchHandler:self.storiesTopController
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        //self.storiesController.searchControllerBackButtonIconDDG = [[UIImage imageNamed:@"Home"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [self.storiesTopController pushContentViewController:self.storiesController animated:NO];
        self.storiesTopController.state = DDGSearchControllerStateHome;
        self.storiesTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                             image:[[UIImage imageNamed:@"Tab-Stories"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                     selectedImage:[[UIImage imageNamed:@"Tab-Stories-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

        [controllers addObject:self.storiesTopController];
    }
    
    
    
    { // configure the favorites view controller
        self.favoritesTopController = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                          homeController:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        
        DDGBookmarksViewController *bookmarks = [[DDGBookmarksViewController alloc] initWithNibName:@"DDGBookmarksViewController" bundle:nil];
        bookmarks.title = NSLocalizedString(@"Favorite Searches", @"View controller title: Saved Searches");
        bookmarks.searchController = self.favoritesTopController;
        bookmarks.searchHandler = self.favoritesTopController;
        
        self.favoritesTopController.state = DDGSearchControllerStateHome;
        self.favoritesTopController.shouldPushSearchHandlerEvents = YES;
        
        
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:self.favoritesTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.storiesMode = DDGStoriesListModeFavorites;
        stories.title = NSLocalizedString(@"Favorite Stories", @"View controller title: Saved Stories");
        
        self.favoritesTabViewController = [[DDGTabViewController alloc] initWithViewControllers:@[stories, bookmarks]];
        self.favoritesTabViewController.controlViewPosition = DDGTabViewControllerControlViewPositionTop;
        self.favoritesTabViewController.controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.favoritesTabViewController.controlView.backgroundColor = [UIColor duckSearchBarBackground];
        
        CGRect controlBounds = self.favoritesTabViewController.controlView.bounds;
        CGSize segmentSize = self.favoritesTabViewController.segmentedControl.frame.size;
        segmentSize.width = controlBounds.size.width - 20.0;
        CGRect controlRect = CGRectMake(controlBounds.origin.x + ((controlBounds.size.width - segmentSize.width) / 2.0),
                                        3.0,
                                        segmentSize.width,
                                        segmentSize.height);
        self.favoritesTabViewController.segmentedControl.frame = CGRectIntegral(controlRect);
        self.favoritesTabViewController.segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
        
        [self.favoritesTabViewController.controlView addSubview:self.favoritesTabViewController.segmentedControl];
        self.favoritesTabViewController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
        self.favoritesTabViewController.delegate = self;
        
        [self.favoritesTopController pushContentViewController:self.favoritesTabViewController animated:NO];
        self.favoritesTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Favorites"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Favorites-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:self.favoritesTopController];
    }
    
    { // configure the recents/history view controller
        self.recentsTopController = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                        homeController:self
                                                                  managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        DDGHistoryViewController* history = [[DDGHistoryViewController alloc] initWithSearchHandler:self.recentsTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]
                                                                                               mode:DDGHistoryViewControllerModeNormal];
        history.title = NSLocalizedString(@"Recent Searches", @"segmented button option and table header: Recent Searches");
        
        self.recentsTopController.state = DDGSearchControllerStateHome;
        self.recentsTopController.shouldPushSearchHandlerEvents = YES;
        
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:self.recentsTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.storiesMode = DDGStoriesListModeRecents;
        stories.title = NSLocalizedString(@"Recent Stories", @"Table section header title");
        
        self.recentsController = [[DDGTabViewController alloc] initWithViewControllers:@[stories, history]];
        self.recentsController.controlViewPosition = DDGTabViewControllerControlViewPositionTop;
        self.recentsController.controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.recentsController.controlView.backgroundColor = [UIColor duckSearchBarBackground];
        
        CGRect controlBounds = self.recentsController.controlView.bounds;
        CGSize segmentSize = self.recentsController.segmentedControl.frame.size;
        segmentSize.width = controlBounds.size.width - 20.0;
        CGRect controlRect = CGRectMake(controlBounds.origin.x + ((controlBounds.size.width - segmentSize.width) / 2.0),
                                        3.0,
                                        segmentSize.width,
                                        segmentSize.height);
        self.recentsController.segmentedControl.frame = CGRectIntegral(controlRect);
        self.recentsController.segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
        
        [self.recentsController.controlView addSubview:self.recentsController.segmentedControl];
        self.recentsController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
        self.recentsController.delegate = self;
        
        [self.recentsTopController pushContentViewController:self.recentsController animated:NO];
        self.recentsTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                             image:[[UIImage imageNamed:@"Tab-Recents"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                     selectedImage:[[UIImage imageNamed:@"Tab-Recents-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:self.recentsTopController];
    }
    
    
    { // configure the settings view controller
        self.settingsTopController = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                         homeController:self
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.settingsTopController.state = DDGSearchControllerStateHome;
        self.settingsController = [[DDGSettingsViewController alloc] initWithDefaults];
        self.settingsController.managedObjectContext = [DDGAppDelegate sharedManagedObjectContext];
        [self.settingsTopController pushContentViewController:self.settingsController animated:NO];
        self.settingsTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Settings-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

        [controllers addObject:self.settingsTopController];
    }
    
    self.tabController.viewControllers = controllers;
    
    //int type = DDGViewControllerTypeHome;
    NSString *homeViewMode = [[NSUserDefaults standardUserDefaults] objectForKey:DDGSettingHomeView];
    if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeRecents]) {
        [self showRecents];
    } else if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeSaved]) {
        [self showFavorites];
    } else if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeStories]) {
        [self showStories];
    } else { //if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeDuck]) {
        [self showDuck];
    }
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.viewDidAppearCompletion) {
        self.viewDidAppearCompletion(self);
    }
}

-(void)viewDidLayoutSubviews
{
    self.topAlignmentConstraint.constant = self.topLayoutGuide.length;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - DDGSearchHandler

- (void)beginSearchInputWithString:(NSString *)string
{
    DDGAddressBarTextField *searchField = [self.searchController.searchControllerDDG.searchBar searchField];
    [searchField becomeFirstResponder];
    searchField.text = string;
    [self.searchController.searchControllerDDG searchFieldDidChange:nil];
}

- (void)prepareForUserInput {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:webVC
                                                                                homeController:self
                                                                          managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
    webVC.searchController = searchController;
    
    [searchController pushContentViewController:webVC animated:NO];
    searchController.state = DDGSearchControllerStateWeb;
    
    [self.slideOverMenuController setContentViewController:searchController];
    
    [searchController.searchBar.searchField becomeFirstResponder];
}


-(void)searchControllerLeftButtonPressed {
    [self.slideOverMenuController showMenu];
}

-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:webVC
                                                                                homeController:self
                                                                          managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
    webVC.searchController = searchController;
    
    [searchController pushContentViewController:webVC animated:NO];
    searchController.state = DDGSearchControllerStateWeb;
    
    [webVC loadStory:story readabilityMode:readabilityMode];
    //self.menuIndexPath = nil;
    
    if (searchController) {
        [self.slideOverMenuController setContentViewController:searchController];
        [self.slideOverMenuController hideMenu];
    }
    
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    DDGSearchController *searchController = [[DDGSearchController alloc] initWithSearchHandler:webVC
                                                                                homeController:self
                                                                          managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
    webVC.searchController = searchController;
    
    [searchController pushContentViewController:webVC animated:NO];
    searchController.state = DDGSearchControllerStateWeb;
    
    [webVC loadQueryOrURL:queryOrURL];
    //self.menuIndexPath = nil;
    
    if (searchController) {
        [self.slideOverMenuController setContentViewController:searchController];
        [self.slideOverMenuController hideMenu];
    }
}

-(void)setSelectedButton:(UIButton*)newlySelectedTabButton
{
    UIColor* selColor = [UIColor duckTabBarForegroundSelected];
    UIColor* unselColor = [UIColor duckTabBarForeground];
    self.searchTabButton.tintColor = newlySelectedTabButton==self.searchTabButton ? selColor : unselColor;
    self.storiesTabButton.tintColor = newlySelectedTabButton==self.storiesTabButton ? selColor : unselColor;
    self.favoritesTabButton.tintColor = newlySelectedTabButton==self.favoritesTabButton ? selColor : unselColor;
    self.recentsTabButton.tintColor = newlySelectedTabButton==self.recentsTabButton ? selColor : unselColor;
    self.settingsTabButton.tintColor = newlySelectedTabButton==self.settingsTabButton ? selColor : unselColor;
}

#pragma mark - DDGTabViewControllerDelegate

- (void)tabViewController:(DDGTabViewController *)tabViewController didSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)tabIndex {
    NSLog(@"tabViewController:didSwitchToViewController:atIndex:%ld", (long)tabIndex);
    [[NSUserDefaults standardUserDefaults] setInteger:tabIndex forKey:DDGSavedViewLastSelectedTabIndex];
    [self setSelectedButton:[self.tabButtons objectAtIndex:tabIndex]];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
