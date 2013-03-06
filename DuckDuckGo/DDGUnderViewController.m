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
#import "DDGStoriesViewController.h"
#import "DDGCache.h"

typedef enum DDGViewControllerType {
    DDGViewControllerTypeHome=0,
    DDGViewControllerTypeSaved,
    DDGViewControllerTypeStories,
    DDGViewControllerTypeSettings
} DDGViewControllerType;

NSString * const DDGViewControllerTypeTitleKey = @"title";
NSString * const DDGViewControllerTypeTypeKey = @"type";
NSString * const DDGViewControllerTypeControllerKey = @"viewController";

@interface DDGUnderViewController ()
@property (nonatomic, strong) NSArray *viewControllerTypes;
@end

@implementation DDGUnderViewController

-(id)initWithHomeViewController:(UIViewController *)homeViewController {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        self.homeViewController = homeViewController;
        
        self.viewControllerTypes = @[
                                     @{DDGViewControllerTypeTitleKey : @"Home",
                                       DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeHome),
                                       DDGViewControllerTypeControllerKey: homeViewController
                                       },
                                     @{DDGViewControllerTypeTitleKey : @"Saved",
                                       DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeSaved)
                                       },
                                     @{DDGViewControllerTypeTitleKey : @"Stories",
                                       DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeStories)
                                       },
                                     @{DDGViewControllerTypeTitleKey : @"Settings",
                                       DDGViewControllerTypeTypeKey: @(DDGViewControllerTypeSettings)
                                       },
        ];        

        self.tableView.scrollsToTop = NO;
        
        self.tableView.backgroundColor = [UIColor colorWithRed:0.161 green:0.173 blue:0.196 alpha:1.000];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        self.clearsSelectionOnViewWillAppear = NO;
		
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)configureViewController:(UIViewController *)viewController {
    [viewController.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    viewController.view.layer.shadowOpacity = 0.75f;
    viewController.view.layer.shadowRadius = 10.0f;
    viewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

-(void)loadStory:(DDGStory *)story {
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    [webVC loadStory:story];
    
    CGRect frame = self.slidingViewController.topViewController.view.frame;
    self.slidingViewController.topViewController = webVC;
    self.slidingViewController.topViewController.view.frame = frame;
    [self configureViewController:webVC];    
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
            return self.viewControllerTypes.count;
        case 1:
		{
            return ![[DDGCache objectForKey:DDGSettingRecordHistory inCache:DDGSettingsCacheName] boolValue] ? 1 : [[DDGHistoryProvider sharedProvider] allHistoryItems].count;
		}
        default:
            return 0;
    };
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DDGUnderViewControllerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	UIImageView *iv;
    if(!cell)
	{
        cell = [[[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil] objectAtIndex:0];
        
		iv = (UIImageView *)[cell viewWithTag:100];
		iv.layer.cornerRadius = 2.0;
    }
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	iv = (UIImageView *)[cell viewWithTag:100];
	iv.image = nil;
    
	UILabel *lbl = (UILabel*)[cell.contentView viewWithTag:200];
    if(indexPath.section == 0)
	{
		[cell.contentView viewWithTag:300].hidden = NO;
		((UIImageView*)[cell.contentView viewWithTag:300]).image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_caret_onclick.png" : @"icon_caret.png"];

		cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_menu-items.png"]];

        lbl.text = [[self.viewControllerTypes objectAtIndex:indexPath.row] objectForKey:DDGViewControllerTypeTitleKey];
		lbl.textColor = (indexPath.row == menuIndex) ? [UIColor whiteColor] : [UIColor  colorWithRed:0x97/255.0 green:0xA2/255.0 blue:0xB6/255.0 alpha:1.0];
		lbl.numberOfLines = 1;
		lbl.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];

        NSDictionary *typeInfo = [self.viewControllerTypes objectAtIndex:indexPath.row];
        DDGViewControllerType type = [[typeInfo objectForKey:DDGViewControllerTypeTypeKey] integerValue];        
        
		switch (type)
		{
			case DDGViewControllerTypeHome:
			{
				iv.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_home_selected.png" : @"icon_home.png"];
                iv.highlightedImage = [UIImage imageNamed:@"icon_home_selected.png"];
			}
				break;
			case DDGViewControllerTypeSaved:
			{
				iv.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_saved-pages_selected.png" : @"icon_saved-pages.png"];
                iv.highlightedImage = [UIImage imageNamed:@"icon_saved-pages_selected.png"];
			}
				break;
			case DDGViewControllerTypeStories:
			{
#warning need a home menu image for stories
				iv.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_saved-pages_selected.png" : @"icon_saved-pages.png"];
                iv.highlightedImage = [UIImage imageNamed:@"icon_saved-pages_selected.png"];
			}
				break;
			case DDGViewControllerTypeSettings:
			{
				iv.image = [UIImage imageNamed:(indexPath.row == menuIndex) ? @"icon_settings_selected.png" : @"icon_settings.png"];
                iv.highlightedImage = [UIImage imageNamed:@"icon_settings_selected.png"];
			}
				break;
		}
		iv.frame = CGRectMake(0, 0, 24, 24);
    }
	else
	{
		[cell.contentView viewWithTag:300].hidden = YES;
		
		cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"new_bg_history-items.png"]];
		lbl.textColor = [UIColor  colorWithRed:0x97/255.0 green:0xA2/255.0 blue:0xB6/255.0 alpha:1.0];
		lbl.font = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        
		if ([[DDGCache objectForKey:DDGSettingRecordHistory inCache:DDGSettingsCacheName] boolValue])
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
			lbl.text = [item objectForKey:@"text"];
		}
		else
		{
			iv.image = [UIImage imageNamed:@"icon_notification.png"];
			lbl.text = @"Recording recents is disabled.\nYou can enable it in settings.";
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		lbl.numberOfLines = 2;
		lbl.font = [UIFont systemFontOfSize:14.0];
		iv.frame = CGRectMake(0, 0, 16, 16);
    }
	iv.center = CGPointMake(22, 22);
	lbl.backgroundColor = cell.contentView.backgroundColor;
    
    return cell;
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
        title.text = @"Recent";
        title.textColor = [UIColor whiteColor];
        title.opaque = NO;
        title.backgroundColor = [UIColor clearColor];
        title.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:13.0];
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
	if (indexPath.section == 1 && ![[DDGCache objectForKey:DDGSettingRecordHistory inCache:DDGSettingsCacheName] boolValue])
		return nil;
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.slidingViewController anchorTopViewOffScreenTo:ECRight animations:nil onComplete:^{
        if(indexPath.section == 0)
		{
			menuIndex = indexPath.row;
            NSDictionary *typeInfo = [self.viewControllerTypes objectAtIndex:menuIndex];
            UIViewController *newTopViewController = [typeInfo objectForKey:DDGViewControllerTypeControllerKey];
            
            if (nil == newTopViewController) {
                DDGViewControllerType type = [[typeInfo objectForKey:DDGViewControllerTypeTypeKey] integerValue];
                switch (type) {
                    case DDGViewControllerTypeSaved:
                        newTopViewController = [[UINavigationController alloc] initWithRootViewController:[[DDGBookmarksViewController alloc] initWithNibName:nil bundle:nil]];
                        break;
                    case DDGViewControllerTypeStories:
                        newTopViewController = [[UINavigationController alloc] initWithRootViewController:[[DDGStoriesViewController alloc] initWithNibName:nil bundle:nil]];                        
                        break;
                    case DDGViewControllerTypeSettings:
                        newTopViewController = [[UINavigationController alloc] initWithRootViewController:[[DDGSettingsViewController alloc] initWithDefaults]];
                        break;
                    case DDGViewControllerTypeHome:
                    default:
                        break;
                }
                
            }
            
            if (nil != newTopViewController) {
                CGRect frame = self.slidingViewController.topViewController.view.frame;
                self.slidingViewController.topViewController = newTopViewController;
                self.slidingViewController.topViewController.view.frame = frame;
                [self.slidingViewController resetTopView];
                
                [self configureViewController:newTopViewController];                
            }
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


@end
