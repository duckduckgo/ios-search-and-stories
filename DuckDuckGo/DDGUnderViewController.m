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
                @"title" : @"Home",
                @"viewController" : homeViewController
            },
            @{
                @"title" : @"Saved Pages",
                @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil]]
            },
            @{
                @"title" : @"Settings",
                @"viewController" : [[UINavigationController alloc] initWithRootViewController:[[DDGSettingsViewController alloc] initWithDefaults]]
            }
        ].mutableCopy;
    
        self.tableView.scrollsToTop = NO;
        
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_bg.png"]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        self.clearsSelectionOnViewWillAppear = NO;

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.textColor = [UIColor whiteColor];
    }
    
    if(indexPath.section == 0)
	{
        cell.textLabel.text = [[viewControllers objectAtIndex:indexPath.row] objectForKey:@"title"];
		switch (indexPath.row)
		{
			case 0:
			{
				cell.imageView.image = [UIImage imageNamed:@"icon_home.png"];
			}
				break;
			case 1:
			{
				cell.imageView.image = [UIImage imageNamed:@"icon_saved-pages.png"];
			}
				break;
			case 2:
			{
				cell.imageView.image = [UIImage imageNamed:@"icon_settings.png"];
			}
				break;
				
		}
    }
	else
	{
        cell.textLabel.text = [[[[DDGHistoryProvider sharedProvider] allHistoryItems] objectAtIndex:indexPath.row] objectForKey:@"text"];
		cell.imageView.image = nil;
    }
    
    // cell separator
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                cell.contentView.bounds.size.height-1.0f,
                                                                cell.contentView.bounds.size.width,
                                                                1.0f)];
    lineView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    lineView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    [cell.contentView addSubview:lineView];

    UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                0.0f,
                                                                cell.contentView.bounds.size.width,
                                                                1.0f)];
    lineView2.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    lineView2.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.03];
    [cell.contentView addSubview:lineView2];
    
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (section == 0 ? 0 : 22);
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 23)];
    [headerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_divider.png"]]];
    
    if(section == 1) {
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width-10, 20)];
        title.text = @"History";
        title.textColor = [UIColor whiteColor];
        title.opaque = NO;
        title.backgroundColor = [UIColor clearColor];
        title.font = [UIFont boldSystemFontOfSize:13.0];
        [headerView addSubview:title];
    }
    
    return headerView;
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
