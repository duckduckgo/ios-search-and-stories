//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGViewController.h"
#import "DDGWebViewController.h"
#import "AFNetworking.h"
#import "DDGCache.h"
#import <QuartzCore/QuartzCore.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGStoriesProvider.h"
#import "DDGSettingsViewController.h"
#import "DDGNewsSourcesViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "UIImage+DDG.h"
#import "NSArray+ConcurrentIteration.h"

@implementation DDGViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" containerViewController:self];
	_searchController.searchHandler = self;
    _searchController.state = DDGSearchControllerStateHome;
    
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_bg.png"]];
    
    topShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_view_shadow_top.png"]];
    topShadow.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 5.0);
    topShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    // shadow gets added to table view in scrollViewDidScroll
    
    if (refreshHeaderView == nil) {
		refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		refreshHeaderView.delegate = self;
		[self.tableView addSubview:refreshHeaderView];
        [refreshHeaderView refreshLastUpdatedDate];
	}
	
	//  update the last update date
	[refreshHeaderView refreshLastUpdatedDate];
    
    // force-decompress all images
    // be careful! we're in a background thread and everything is changing under our feet
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for(NSString *cacheName in @[@"storyImages", @"sourceImages"]) {
            NSDictionary *cache = [DDGCache cacheNamed:cacheName].copy;
            for(NSString *key in cache) {
                UIImage *image = [cache objectForKey:key];
                image = [UIImage ddg_decompressedImageWithImage:image];
                [DDGCache updateObject:image forKey:key inCache:cacheName];
            }
        }        
    });
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_searchController clearAddressBar];
    
    [self beginDownloadingStories];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // if we animated out, animate back in
    if(_tableView.alpha == 0) {
        _tableView.transform = CGAffineTransformMakeScale(2, 2);
        [UIView animateWithDuration:0.3 animations:^{
            _tableView.alpha = 1;
            _tableView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if (IPHONE)
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	else
        return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        
    [_searchController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView.contentOffset.y <= 0) {
        [refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];

        CGRect f = topShadow.frame;
        f.origin.y = scrollView.contentOffset.y;
        topShadow.frame = f;
        
        [_tableView insertSubview:topShadow atIndex:0];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    [self beginDownloadingStories];
    
    if([[DDGCache objectForKey:@"quack" inCache:@"settings"] boolValue]) {
        SystemSoundID quack;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"quack" ofType:@"wav"];
        NSURL *url = [NSURL URLWithString:path];
        AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &quack);
        AudioServicesPlaySystemSound(quack);
    }
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
    return isRefreshing;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
    return [DDGCache objectForKey:@"storiesUpdated" inCache:@"misc"];
}

#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    // this is the settings button, so let's load the settings controller
    DDGSettingsViewController *settingsVC = [[DDGSettingsViewController alloc] initWithDefaults];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentModalViewController:navController animated:YES];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {    
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    [webVC loadQueryOrURL:queryOrURL];
    
    // because we want the search bar to stay in place, we need to do custom animation here.
   
    [UIView animateWithDuration:0.3 animations:^{
        _tableView.transform = CGAffineTransformMakeScale(2, 2);
        _tableView.alpha = 0;
    } completion:^(BOOL finished) {
        _tableView.transform = CGAffineTransformIdentity;
        [self.navigationController pushViewController:webVC animated:NO];
    }];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *TwoLineCellIdentifier = @"TwoLineTopicCell";
	static NSString *OneLineCellIdentifier = @"OneLineTopicCell";

    NSArray *stories = [[DDGStoriesProvider sharedProvider] stories];
    NSDictionary *story = [stories objectAtIndex:indexPath.row];
    
    NSString *cellID = nil;
    if([[story objectForKey:@"title"] sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(tv.bounds.size.width, 60) lineBreakMode:UILineBreakModeWordWrap].height < 19)
        cellID = OneLineCellIdentifier;
    else
        cellID = TwoLineCellIdentifier;

    
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:cellID owner:self options:nil];
        cell = _loadedCell;
        self.loadedCell = nil;
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:200];
	label.text = [story objectForKey:@"title"];
    if([[DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"readStories"] boolValue])
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    else
        label.textColor = [UIColor whiteColor];
    
    // load article image
    UIImageView *articleImageView = (UIImageView *)[cell.contentView viewWithTag:100];
    articleImageView.image = [DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"storyImages"];
    [articleImageView setContentMode:UIViewContentModeScaleAspectFill];
    // load site favicon image
    UIImageView *faviconImageView = (UIImageView *)[cell.contentView viewWithTag:300];
    faviconImageView.image = [DDGCache objectForKey:[story objectForKey:@"feed"] inCache:@"sourceImages"];
    
    // resize label, backgroundImageView, faviconImageView as needed
    UIView *backgroundImageView = (UIImageView *)[cell.contentView viewWithTag:400];
    backgroundImageView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"topic_cell_background.png"]];
    
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [DDGStoriesProvider sharedProvider].stories.count;
}

#pragma  mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *story = [[DDGStoriesProvider sharedProvider].stories objectAtIndex:indexPath.row];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // mark the story as read
        [DDGCache setObject:@(YES) forKey:[story objectForKey:@"id"] inCache:@"readStories"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5]; // wait for the animation to complete
        });
    });

    NSString *escapedStoryURL = [[story objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self loadQueryOrURL:escapedStoryURL];
}

#pragma mark - Loading popular stories

// downloads stories asynchronously
-(void)beginDownloadingStories {
    isRefreshing = YES;
    
    [[DDGStoriesProvider sharedProvider] downloadSourcesFinished:^{
        if(![DDGCache objectForKey:@"notFirstLaunch" inCache:@"misc"]) {
            [DDGCache setObject:@(YES) forKey:@"notFirstLaunch" inCache:@"misc"];
            
            UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:[[DDGNewsSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped]];
            [self presentModalViewController:navC animated:YES];
        }
        
        [[DDGStoriesProvider sharedProvider] downloadStoriesInTableView:self.tableView finished:^{
            isRefreshing = NO;
            [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        }];
        
    }];
}

@end
