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
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* toolbarTop;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* homeToolbarLeft;
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

-(void)setHideToolbar:(BOOL)hideToolbar withScrollview:(UIScrollView*)scrollView
{
    CGFloat newConstant = hideToolbar ? 0 : -50;
    if(self.toolbarTop.constant!=newConstant) {
        self.toolbarTop.constant = newConstant;
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutSubviews];
            scrollView.contentInset = UIEdgeInsetsMake(0, 0, -newConstant, 0);
            scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, -newConstant, 0);
        }];
    }
}


-(void)registerScrollableContent:(UIScrollView*)contentView
{
    contentView.contentInset = contentInsets;
    contentView.scrollIndicatorInsets = contentInsets;
}

-(void)setAlternateButtonBar:(UIView *)alternateButtonBar {
    [self setAlternateButtonBar:alternateButtonBar animated:FALSE];
}

-(void)setAlternateButtonBar:(UIView *)alternateButtonBar animated:(BOOL)animated {
    if(alternateButtonBar!=_alternateButtonBar) {
        if(alternateButtonBar) {
            [self.alternateToolbarContainer addSubview:alternateButtonBar];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeLeading
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeLeading
                                                                                      multiplier:1 constant:0]];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                      multiplier:1 constant:0]];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeTop
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeTop
                                                                                      multiplier:1 constant:0]];
            [self.alternateToolbarContainer addConstraint:[NSLayoutConstraint constraintWithItem:alternateButtonBar attribute:NSLayoutAttributeHeight
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.alternateToolbarContainer
                                                                                       attribute:NSLayoutAttributeHeight
                                                                                      multiplier:1 constant:0]];
            [self.view layoutSubviews];
            
            self.altToolbarLeft.priority = 950;
            self.toolbarTop.constant = -50;
            
            if(animated) {
                [UIView animateWithDuration:0.25 animations:^{ [self.view layoutSubviews]; }];
            } else {
                [self.view layoutSubviews];
            }
        } else {
            // show the default home button bar
            self.altToolbarLeft.priority = 850;
            self.toolbarTop.constant = -50;
            [self.toolbarContainer setNeedsUpdateConstraints];
            if(animated) {
                [UIView animateWithDuration:0.25 animations:^{
                    [self.view layoutSubviews];
                } completion:^(BOOL finished) {
                    //                [_alternateButtonBar removeFromSuperview];
                    //                [self.alternateToolbarContainer removeConstraints:self.alternateToolbarContainer.constraints];
                }];
            } else {
                [self.view layoutSubviews];
            }
        }
    }
    _alternateButtonBar = alternateButtonBar;
    //    self.searchButtonBar.hidden = TRUE;
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
    [self setSelectedButton:self.recentsTabButton];
}

-(IBAction)showFavorites {
    if(self.tabController.selectedViewController!=self.favoritesTopController) {
        self.tabController.selectedViewController = self.favoritesTopController;
    } else {
        [self.favoritesTabViewController duckGoToTopLevel];
    }
    [self setSelectedButton:self.favoritesTabButton];
}

-(IBAction)showStories {
    if(self.tabController.selectedViewController!=self.storiesTopController) {
       self.tabController.selectedViewController = self.storiesTopController;
    } else {
        [self.storiesController duckGoToTopLevel];
    }
    [self setSelectedButton:self.storiesTabButton];
}

-(IBAction)showDuck {
    if(self.tabController.selectedViewController!=self.searchTopController) {
        self.tabController.selectedViewController = self.searchTopController;
    }
    [self.searchController duckGoToTopLevel];
    [self setSelectedButton:self.searchTabButton];
}

-(IBAction)showSettings {
    if(self.tabController.selectedViewController!=self.settingsTopController) {
        self.tabController.selectedViewController = self.settingsTopController;
    } else {
        [self.settingsController duckGoToTopLevel];
    }
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
    self.tabContentView.backgroundColor = [UIColor duckSearchBarBackground]; // hack to workaround app switcher flickering issue
    [self.tabContentView addSubview:self.tabController.view];
    [self.tabController didMoveToParentViewController:self];
    self.tabController.tabBar.hidden = TRUE;
    contentInsets = UIEdgeInsetsMake(0, 0, 50, 0);
    self.view.backgroundColor = [UIColor duckSearchBarBackground];
    
    NSMutableArray* controllers = [NSMutableArray new];
    
    { // configure the search view controller
        self.searchTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                  managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.searchTopController.state = DDGSearchControllerStateHome;
        self.searchController = [[DDGDuckViewController alloc] initWithSearchController:self.searchTopController
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        [self.searchTopController pushContentViewController:self.searchController animated:NO];
        self.searchTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                            image:[[UIImage imageNamed:@"Tab-Search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                    selectedImage:[[UIImage imageNamed:@"Tab-Search-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:self.searchTopController];
    }
    
    { // configure the stories view controller
        self.storiesTopController = [[DDGSearchController alloc] initWithHomeController:self
                                                                   managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
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
        
        [self.favoritesTopController pushContentViewController:self.favoritesTabViewController animated:NO];
        self.favoritesTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Favorites"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Favorites-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
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
        
        self.recentsTopController.state = DDGSearchControllerStateHome;
        
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:self.recentsTopController
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.storiesMode = DDGStoriesListModeRecents;
        stories.title = NSLocalizedString(@"Recent Stories", @"Table section header title");
        
        self.recentsController = [[DDGTabViewController alloc] init];
        self.recentsController.viewControllers = @[ stories, history];
        self.recentsController.segmentAlignmentView = self.recentsTopController.searchBar;
        self.recentsController.delegate = self;
        
        [self.recentsTopController pushContentViewController:self.recentsController animated:NO];
        self.recentsTopController.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                                             image:[[UIImage imageNamed:@"Tab-Recents"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                                     selectedImage:[[UIImage imageNamed:@"Tab-Recents-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:self.recentsTopController];
        
        self.recentsController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
    }
    
    
    { // configure the settings view controller
        self.settingsTopController = [[DDGSearchController alloc] initWithHomeController:self
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
}

-(void)viewDidLayoutSubviews
{
    self.topAlignmentConstraint.constant = self.topLayoutGuide.length;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
