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
#import "DDGUnderViewController.h"
#import "DDGDuckViewController.h"
#import "DDGBookmarksViewController.h"
#import "UIColor+DDG.h"

@interface DDGHomeViewController ()

//@property (nonatomic, strong) DDGSearchController* searchController;
@property (nonatomic, strong) DDGStoriesViewController* storiesController;
@property (nonatomic, strong) DDGSettingsViewController* settingsController;
@property (nonatomic, strong) DDGDuckViewController* searchController;
@property (nonatomic, strong) DDGTabViewController* favoritesTabViewController;
@property (nonatomic, strong) DDGTabViewController* recentsController;

@end

@implementation DDGHomeViewController


-(void)showRecents {
    
}

-(void)showFavorites {
    
}

-(void)showDuck {
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tabBar.selectedImageTintColor = [UIColor duckTabBarForegroundSelected];
    self.tabBar.tintColor = [UIColor duckTabBarForeground];
    self.tabBar.backgroundColor = [UIColor duckTabBarBackground];
    
    NSMutableArray* controllers = [NSMutableArray new];
    
    { // configure the search view controller
        DDGSearchController* search = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        search.state = DDGSearchControllerStateHome;
        search.shouldPushSearchHandlerEvents = TRUE;
        self.searchController = [[DDGDuckViewController alloc] initWithSearchController:search];
        [search pushContentViewController:self.searchController animated:NO];
        search.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Search-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:search];
    }
    
    { // configure the stories view controller
        DDGSearchController* search = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        search.shouldPushSearchHandlerEvents = YES;
        self.storiesController = [[DDGStoriesViewController alloc] initWithSearchHandler:search
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        self.storiesController.searchControllerBackButtonIconDDG = [[UIImage imageNamed:@"Home"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [search pushContentViewController:self.storiesController animated:NO];
        search.state = DDGSearchControllerStateHome;
        search.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Stories"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Stories-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

        [controllers addObject:search];
    }
    
    
    
    { // configure the favorites view controller
        DDGSearchController* search = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        DDGBookmarksViewController *bookmarks = [[DDGBookmarksViewController alloc] initWithNibName:@"DDGBookmarksViewController" bundle:nil];
        bookmarks.title = NSLocalizedString(@"Searches", @"View controller title: Saved Searches");
        
        search.state = DDGSearchControllerStateHome;
        search.shouldPushSearchHandlerEvents = YES;
        
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:search
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.savedStoriesOnly = YES;
        stories.title = NSLocalizedString(@"Stories", @"View controller title: Saved Stories");
        
        self.favoritesTabViewController = [[DDGTabViewController alloc] initWithViewControllers:@[bookmarks, stories]];
        
        bookmarks.searchController = search;
        bookmarks.searchHandler = search;
        
        self.favoritesTabViewController.controlViewPosition = DDGTabViewControllerControlViewPositionTop;
        self.favoritesTabViewController.controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.favoritesTabViewController.controlView.backgroundColor = [UIColor duckLightGray];
        [self.favoritesTabViewController.segmentedControl sizeToFit];
        
        CGRect controlBounds = self.favoritesTabViewController.controlView.bounds;
        CGSize segmentSize = self.favoritesTabViewController.segmentedControl.frame.size;
        segmentSize.width = controlBounds.size.width - 10.0;
        CGRect controlRect = CGRectMake(controlBounds.origin.x + ((controlBounds.size.width - segmentSize.width) / 2.0),
                                        controlBounds.origin.y + ((controlBounds.size.height - segmentSize.height) / 2.0),
                                        segmentSize.width,
                                        segmentSize.height);
        self.favoritesTabViewController.segmentedControl.frame = CGRectIntegral(controlRect);
        self.favoritesTabViewController.segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
        self.favoritesTabViewController.searchControllerBackButtonIconDDG = [[UIImage imageNamed:@"Saved"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [self.favoritesTabViewController.controlView addSubview:self.favoritesTabViewController.segmentedControl];
        self.favoritesTabViewController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
        self.favoritesTabViewController.delegate = self;
        
        [search pushContentViewController:self.favoritesTabViewController animated:NO];
        search.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Favorites"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Favorites-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:search];
    }
    
    { // configure the recents/history view controller
        DDGSearchController* search = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        DDGHistoryViewController* history = [[DDGHistoryViewController alloc] initWithSearchHandler:self
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]
                                                                                               mode:DDGHistoryViewControllerModeUnder];
        
        history.title = NSLocalizedString(@"Recent Searches", @"segmented button option and table header: Recent Searches");
        
        search.state = DDGSearchControllerStateHome;
        search.shouldPushSearchHandlerEvents = YES;
        
        DDGStoriesViewController *stories = [[DDGStoriesViewController alloc] initWithSearchHandler:search
                                                                               managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        stories.savedStoriesOnly = YES;
        stories.title = NSLocalizedString(@"Recent Stories", @"Table section header title");
        //        history.searchController = search;
        //        history.searchHandler = search;
        
        self.recentsController = [[DDGTabViewController alloc] initWithViewControllers:@[stories, history]];
        
        self.recentsController.controlViewPosition = DDGTabViewControllerControlViewPositionTop;
        self.recentsController.controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.recentsController.controlView.backgroundColor = [UIColor duckLightGray];
        [self.recentsController.segmentedControl sizeToFit];
        
        CGRect controlBounds = self.recentsController.controlView.bounds;
        CGSize segmentSize = self.recentsController.segmentedControl.frame.size;
        segmentSize.width = controlBounds.size.width - 10.0;
        CGRect controlRect = CGRectMake(controlBounds.origin.x + ((controlBounds.size.width - segmentSize.width) / 2.0),
                                        controlBounds.origin.y + ((controlBounds.size.height - segmentSize.height) / 2.0),
                                        segmentSize.width,
                                        segmentSize.height);
        self.recentsController.segmentedControl.frame = CGRectIntegral(controlRect);
        self.recentsController.segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
        self.recentsController.searchControllerBackButtonIconDDG = [[UIImage imageNamed:@"Saved"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [self.recentsController.controlView addSubview:self.recentsController.segmentedControl];
        self.recentsController.currentViewControllerIndex = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSavedViewLastSelectedTabIndex];
        self.recentsController.delegate = self;
        
        [search pushContentViewController:self.recentsController animated:NO];
        search.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Recents"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Recents-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [controllers addObject:search];
        
        
        ////////////
        //    self.recentsController.additionalSectionsDelegate = self;
        //    self.recentsController.view.frame = self.view.bounds;
        //    self.recentsController.tableView.scrollsToTop = NO;
        //    [self.recentsController.tableView registerNib:[UINib nibWithNibName:@"DDGMenuItemCell" bundle:nil]
        //                           forCellReuseIdentifier:@"DDGMenuItemCell"];
        //
        //    self.recentsController.overhangWidth = 74;
        

    }
    
    
    { // configure the settings view controller
        DDGSearchController* search = [[DDGSearchController alloc] initWithSearchHandler:self
                                                                    managedObjectContext:[DDGAppDelegate sharedManagedObjectContext]];
        search.state = DDGSearchControllerStateHome;
        self.settingsController = [[DDGSettingsViewController alloc] initWithDefaults];
        self.settingsController.managedObjectContext = [DDGAppDelegate sharedManagedObjectContext];
        [search pushContentViewController:self.settingsController animated:NO];
        search.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil
                                                          image:[[UIImage imageNamed:@"Tab-Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                                  selectedImage:[[UIImage imageNamed:@"Tab-Settings-Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

        [controllers addObject:search];
    }
    
    self.viewControllers = controllers;
    
    //int type = DDGViewControllerTypeHome;
    NSString *homeViewMode = [[NSUserDefaults standardUserDefaults] objectForKey:DDGSettingHomeView];
    if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeRecents]) {
        [self showRecents];
    } else if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeSaved]) {
        [self showFavorites];
    } else if ([homeViewMode isEqualToString:DDGSettingHomeViewTypeDuck]) {
        [self showDuck];
    }
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.viewDidAppearCompletion) {
        self.viewDidAppearCompletion(self);
    }
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

@end
