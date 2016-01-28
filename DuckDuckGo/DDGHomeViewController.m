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
#include "DDGSearchHandler.h"
#import "UIViewController+DDGSearchController.h"
#import "DDGTraitHelper.h"

@interface DDGHomeViewController () {
    UIEdgeInsets contentInsets;
}

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

@property (nonatomic, strong) IBOutlet UIView* searchButtonBar;
@property (nonatomic, strong) IBOutlet UIButton* storiesTabButton;
@property (nonatomic, strong) IBOutlet UIButton* settingsTabButton;
@property (nonatomic, strong) IBOutlet UIButton* searchTabButton;
@property (nonatomic, strong) IBOutlet UIButton* favoritesTabButton;
@property (nonatomic, strong) IBOutlet UIButton* recentsTabButton;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topAlignmentConstraint;

@property (nonatomic, strong) IBOutlet UIView* toolbarContainer;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* toolbarTop;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* homeToolbarLeft;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* homeToolbarRight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* altToolbarLeft;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* tabBarTopBorderConstraint; // this exists to force the border to be 0.5px
@end

@implementation DDGHomeViewController


+(DDGHomeViewController*)newHomeController {
  return [[DDGHomeViewController alloc] initWithNibName:@"DDGHomeViewController" bundle:nil];
}

-(BOOL)hideTabBar {
    return self.searchButtonBar.hidden;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.altToolbarLeft.priority = 850;
    self.toolbarTop.constant = -50;
    [self.view layoutSubviews];
}

-(void)registerScrollableContent:(UIScrollView*)contentView
{
    contentView.contentInset = contentInsets;
    contentView.scrollIndicatorInsets = contentInsets;
}


-(id<DDGSearchHandler>)currentSearchHandler
{
    [self view]; // initialise the view controllers/search handlers, if we haven't already
    UIViewController* selectedVC = self.tabController.selectedViewController;
    if([selectedVC conformsToProtocol:@protocol(DDGSearchHandler)]) {
        return (id<DDGSearchHandler>)selectedVC;
    } else {
        return self.searchTopController;
    }
}

-(IBAction)showRecents {
    if(self.tabController.selectedViewController!=self.recentsTopController) {
        self.tabController.selectedViewController = self.recentsTopController;
    } else {
        [self.recentsController duckGoToTopLevel];
    }
}

-(IBAction)showFavorites {
    [self showSaved];
}

-(IBAction)showStories {
    if(self.tabController.selectedViewController!=self.storiesTopController) {
       self.tabController.selectedViewController = self.storiesTopController;
    } else {
        [self.storiesController duckGoToTopLevel];
    }
}

-(IBAction)showDuck {
    [self showSearchAndPrepareInput];
}

-(IBAction)showSettings {
    if(self.tabController.selectedViewController!=self.settingsTopController) {
        self.tabController.selectedViewController = self.settingsTopController;
    } else {
        [self.settingsController duckGoToTopLevel];
    }
}

-(void)showSearchAndPrepareInput {
    if(self.tabController.selectedViewController!=self.searchTopController) {
        self.tabController.selectedViewController = self.searchTopController;
    }
    [self.searchController duckGoToTopLevel];
}

-(void)showSaved {
    if(self.tabController.selectedViewController!=self.favoritesTopController) {
        self.tabController.selectedViewController = self.favoritesTopController;
    } else {
        [self.favoritesTabViewController duckGoToTopLevel];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBarTopBorderConstraint.constant = 0.5f;
    
    self.tabController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
    self.tabController.delegate = self;
    [self addChildViewController:self.tabController];
    self.tabController.view.frame = self.tabContentView.frame;
    self.tabContentView.backgroundColor = [UIColor duckSearchBarBackground]; // hack to workaround app switcher flickering issue
    [self.tabContentView addSubview:self.tabController.view];
    [self.tabController didMoveToParentViewController:self];
    self.tabController.tabBar.hidden = TRUE;
    contentInsets = UIEdgeInsetsMake(0, 0, 50, 0);
    self.view.backgroundColor = [UIColor duckSearchBarBackground];
    [self setUpTabBar];
    
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
}

-(void)viewDidLayoutSubviews
{
    self.topAlignmentConstraint.constant = self.topLayoutGuide.length;
    [self.view layoutIfNeeded]; // this seems wrong, but if we don't have it then we crash on iOS7
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpTabBar {
    
    NSMutableArray* controllers = [NSMutableArray new];
    
    { // configure the search view controller
        self.searchTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                  managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.searchTopController.state = DDGSearchControllerStateHome;
        self.searchController = [[DDGDuckViewController alloc] initWithSearchController:self.searchTopController
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        [self.searchTopController setContentViewController:self.searchController tabPosition:0 animated:NO];
        self.searchTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                            image:[UIImage imageNamed:@"Tab-Search"]
                                                                    selectedImage:[UIImage imageNamed:@"Tab-Search-Active"]];
        [controllers addObject:self.searchTopController];
    }
    
    { // configure the stories view controller
        self.storiesTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.storiesController = [[DDGStoriesViewController alloc] initWithSearchHandler:self.storiesTopController
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        //self.storiesController.searchControllerBackButtonIconDDG = [[UIImage imageNamed:@"Home"];
        
        [self.storiesTopController setContentViewController:self.storiesController tabPosition:1 animated:NO];
        self.storiesTopController.state = DDGSearchControllerStateHome;
        self.storiesTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                             image:[UIImage imageNamed:@"Tab-Stories"]
                                                                     selectedImage:[UIImage imageNamed:@"Tab-Stories-Active"]];
        
        [controllers addObject:self.storiesTopController];
    }
    
    
    
    { // configure the favorites view controller
        self.favoritesTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                     managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        
        DDGBookmarksViewController *bookmarks = [[DDGBookmarksViewController alloc] initWithNibName:@"DDGBookmarksViewController" bundle:nil];
        bookmarks.title = NSLocalizedString(@"Favorite Searches", @"View controller title: Saved Searches");
        bookmarks.searchController = self.favoritesTopController;
        bookmarks.searchHandler = self.favoritesTopController;
        
        self.favoritesTopController.state = DDGSearchControllerStateHome;
        
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:self.favoritesTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.storiesMode = DDGStoriesListModeFavorites;
        stories.title = NSLocalizedString(@"Favorite Stories", @"View controller title: Saved Stories");
        
        self.favoritesTabViewController = [[DDGTabViewController alloc] init];
        self.favoritesTabViewController.viewControllers = @[stories, bookmarks];
        self.favoritesTabViewController.segmentAlignmentView = self.favoritesTopController.searchBar;
        self.favoritesTabViewController.delegate = self;
        
        [self.favoritesTopController setContentViewController:self.favoritesTabViewController tabPosition:2 animated:NO];
        self.favoritesTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                               image:[UIImage imageNamed:@"Tab-Favorites"]
                                                                       selectedImage:[UIImage imageNamed:@"Tab-Favorites-Active"]];
        [controllers addObject:self.favoritesTopController];
        
        self.favoritesTabViewController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
    }
    
    { // configure the recents/history view controller
        self.recentsTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        DDGHistoryViewController* history = [[DDGHistoryViewController alloc] initWithSearchHandler:self.recentsTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]
                                                                                               mode:DDGHistoryViewControllerModeNormal];
        history.title = NSLocalizedString(@"Recent Searches", @"segmented button option and table header: Recent Searches");
        
        self.recentsTopController.state   = DDGSearchControllerStateHome;
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:self.recentsTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.storiesMode = DDGStoriesListModeRecents;
        stories.title = NSLocalizedString(@"Recent Stories", @"Table section header title");
        
        self.recentsController = [[DDGTabViewController alloc] init];
        self.recentsController.viewControllers = @[ stories, history];
        self.recentsController.segmentAlignmentView = self.recentsTopController.searchBar;
        self.recentsController.delegate = self;
        
        [self.recentsTopController setContentViewController:self.recentsController tabPosition:3 animated:NO];
        self.recentsTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                             image:[UIImage imageNamed:@"Tab-Recents"]
                                                                     selectedImage:[UIImage imageNamed:@"Tab-Recents-Active"]];
        [controllers addObject:self.recentsTopController];
        
        self.recentsController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
    }
    
    
    { // configure the settings view controller
        self.settingsTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.settingsTopController.state             = DDGSearchControllerStateHome;
        self.settingsController                      = [[DDGSettingsViewController alloc] initWithDefaults];
        self.settingsController.managedObjectContext = [DDGAppDelegate sharedManagedObjectContext];
        [self.settingsTopController setContentViewController:[self.settingsController duckContainerController] tabPosition:4 animated:NO];
        self.settingsTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                              image:[UIImage imageNamed:@"Tab-Settings"]
                                                                      selectedImage:[UIImage imageNamed:@"Tab-Settings-Active"]];
        [controllers addObject:self.settingsTopController];
    }
    
    self.tabController.viewControllers = controllers;
}

#pragma mark - DDGTabViewControllerDelegate

- (void)tabViewController:(DDGTabViewController *)tabViewController didSwitchToViewController:(UIViewController *)viewController atIndex:(NSInteger)tabIndex {
    [[NSUserDefaults standardUserDefaults] setInteger:tabIndex forKey:DDGSavedViewLastSelectedTabIndex];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark == Check and Load Settings 
- (void)checkAndRefreshSettings {
    // On The iPad, because of the custom split view controller & the split view for iPad we need to ensure that the settings get's reload upon refresh
    if(self.tabController.selectedViewController == self.settingsTopController ) {
        if (IPAD) {
            if (self.settingsController.searchControllerDDG.contentControllers.count > 1) {
                [self.settingsController.searchControllerDDG popContentViewControllerAnimated:NO];
            }
        }
    }
}

@end
