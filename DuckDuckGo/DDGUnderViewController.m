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
#import "DDGCache.h"

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
        
        self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_texture-dark.png"]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        self.clearsSelectionOnViewWillAppear = NO;

        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
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
		{
            return ![[DDGCache objectForKey:@"history" inCache:@"settings"] boolValue] ? 1 : [[DDGHistoryProvider sharedProvider] allHistoryItems].count;
		}
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
        
		cell.imageView.image = [UIImage imageNamed:@"spacer23x23.png"];

		UIImageView *iv  = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)];
		iv.layer.cornerRadius = 2.0;
		[cell.contentView addSubview:iv];
		iv.tag = 100;
		iv.contentMode = UIViewContentModeScaleAspectFit;
		iv.center = cell.imageView.center;
    }
	cell.imageView.image = [UIImage imageNamed:@"spacer23x23.png"];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	((UIImageView *)[cell viewWithTag:100]).image = nil;
    
    if(indexPath.section == 0)
	{
		cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_menu-items.png"]];
        cell.textLabel.text = [[viewControllers objectAtIndex:indexPath.row] objectForKey:@"title"];
		cell.textLabel.textColor = (indexPath.row == menuIndex) ? [UIColor whiteColor] : [UIColor  colorWithRed:0x97/255.0 green:0xA2/255.0 blue:0xB6/255.0 alpha:1.0];
		cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_caret.png"] highlightedImage:[UIImage imageNamed:@"icon_caret_onclick.png"]];
		cell.textLabel.numberOfLines = 1;
		cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue Medium" size:18]; //[UIFont boldSystemFontOfSize:17.0];
		switch (indexPath.row)
		{
			case 0:
			{
				
				cell.imageView.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_home_selected.png" : @"icon_home.png"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"icon_home_selected.png"];
			}
				break;
			case 1:
			{
				cell.imageView.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_saved-pages_selected.png" : @"icon_saved-pages.png"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"icon_saved-pages_selected.png"];
			}
				break;
			case 2:
			{
				cell.imageView.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_settings_selected.png" : @"icon_settings.png"];
                cell.imageView.highlightedImage = [UIImage imageNamed:@"icon_settings_selected.png"];
			}
				break;
		}
    }
	else
	{
		cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_history-items.png"]];
		cell.textLabel.textColor = [UIColor  colorWithRed:0x97/255.0 green:0xA2/255.0 blue:0xB6/255.0 alpha:1.0];
		
		if ([[DDGCache objectForKey:@"history" inCache:@"settings"] boolValue])
		{
			// we have history and it is enabled
			NSDictionary *item = [[[DDGHistoryProvider sharedProvider] allHistoryItems] objectAtIndex:indexPath.row];
			
			if ([[item objectForKey:@"kind"] isEqualToString:@"search"] || [[item objectForKey:@"kind"] isEqualToString:@"suggestion"])
			{
				((UIImageView *)[cell viewWithTag:100]).image = [UIImage imageNamed:@"search_icon.png"];
			}
			else if ([[item objectForKey:@"kind"] isEqualToString:@"feed"])
			{
				((UIImageView *)[cell viewWithTag:100]).image = [DDGCache objectForKey:[item objectForKey:@"feed"] inCache:@"sourceImages"];
			}
			cell.textLabel.text = [item objectForKey:@"text"];
		}
		else
		{
			cell.imageView.image = [UIImage imageNamed:@"reminder_bubble.png"];
			cell.textLabel.text = @"Record History is disabled.\nYou can enable it in settings.";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		cell.accessoryView = nil;
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    }
	cell.textLabel.backgroundColor = cell.contentView.backgroundColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[cell viewWithTag:100].center = CGPointMake(cell.contentView.frame.size.height/2, cell.contentView.frame.size.height/2);
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (section == 0 ? 0 : 23);
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return (section == 0 ? 0 : 1);
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 23)];
    [headerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_divider.png"]]];
    
    if (section == 1)
	{
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

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 1)];
    [footerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"end_of_list_highlight.png"]]];
    
    return footerView;
}


#pragma mark - Table view delegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1 && ![[DDGCache objectForKey:@"history" inCache:@"settings"] boolValue])
		return nil;
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        if(indexPath.section == 0)
		{
			menuIndex = indexPath.row;
            UIViewController *newTopViewController = [[viewControllers objectAtIndex:menuIndex] objectForKey:@"viewController"];
            
            CGRect frame = self.slidingViewController.topViewController.view.frame;
            self.slidingViewController.topViewController = newTopViewController;
            self.slidingViewController.topViewController.view.frame = frame;
            [self.slidingViewController resetTopView];
            
            [self configureViewController:newTopViewController];
        }
		else if(indexPath.section == 1)
		{
			NSDictionary *historyItem = [[[DDGHistoryProvider sharedProvider] allHistoryItems] objectAtIndex:indexPath.row];
			NSString *queryOrURL;
			if ([[historyItem objectForKey:@"kind"] isEqualToString:@"feed"])
				queryOrURL = [historyItem objectForKey:@"url"];
			else
				queryOrURL = [historyItem objectForKey:@"text"];
            [self loadQueryOrURL:queryOrURL];
            [self.slidingViewController resetTopView];
        }
    }];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end
