//
//  DDGUnderViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 8/14/12.
//
//

#import "DDGUnderViewController.h"
#import "ECSlidingViewController.h"
#import "DDGHomeViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGWebViewController.h"
#import "DDGHistoryProvider.h"
#import "DDGBookmarksViewController.h"

@implementation DDGUnderViewController

-(id)initWithHomeViewController:(UIViewController *)homeViewController {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        self.homeViewController = homeViewController;
        viewControllers = @[
            @{
                @"title" : @"Stories",
                @"viewController" : homeViewController
            },
            @{
                @"title" : @"Saved",
                @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil]]
            },
            @{
                @"title" : @"Settings",
                @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGSettingsViewController alloc] initWithDefaults]]
            }
        ].mutableCopy;
    
        self.tableView.scrollsToTop = NO;
        
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_bg.png"]];
        self.tableView.separatorColor = [UIColor colorWithWhite:0 alpha:0.25];

        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)configureViewController:(UIViewController *)viewController {
    [viewController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    viewController.view.layer.shadowOpacity = 0.75f;
    viewController.view.layer.shadowRadius = 10.0f;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    [webVC loadQueryOrURL:queryOrURL];
    
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = webVC;
    self.slidingViewController.topViewController.view.frame = frame;
    [self configureViewController:webVC];
}

-(void)loadHomeViewController; {
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = _homeViewController;
    self.slidingViewController.topViewController.view.frame = frame;
    [self configureViewController:_homeViewController];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return viewControllers.count;
        case 1:
            return [[DDGHistoryProvider sharedProvider] allHistoryItems].count;
        default:
            return 0;
    };
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return (section == 1 ? @"Recent" : nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    if(indexPath.section == 0) {
        cell.textLabel.text = [[viewControllers objectAtIndex:indexPath.row] objectForKey:@"title"];
    } else {
        cell.textLabel.text = [[[[DDGHistoryProvider sharedProvider] allHistoryItems] objectAtIndex:indexPath.row] objectForKey:@"text"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        if(indexPath.section == 0) {
            UIViewController *newTopViewController = [[viewControllers objectAtIndex:indexPath.row] objectForKey:@"viewController"];
            
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
            
            [self configureViewController:newTopViewController];
        } else if(indexPath.section == 1) {
            [self loadQueryOrURL:[[[[DDGHistoryProvider sharedProvider] allHistoryItems] objectAtIndex:indexPath.row] objectForKey:@"text"]];
            [self.slidingViewController resetTopView];
        }
    }];
}

@end
