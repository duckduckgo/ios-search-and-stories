//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGHomeViewController.h"
#import "DDGWebViewController.h"
#import "AFNetworking.h"
#import "DDGCache.h"
#import <QuartzCore/QuartzCore.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGNewsProvider.h"
#import "DDGSettingsViewController.h"
#import "DDGChooseSourcesViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGStory.h"
#import "DDGScrollbarClockView.h"
#import "ECSlidingViewController.h"
#import "DDGUnderViewController.h"

@implementation DDGHomeViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" containerViewController:self];
	_searchController.searchHandler = self;
    _searchController.state = DDGSearchControllerStateHome;
    
    linen = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_bg.png"]];
    _tableView.separatorColor = [UIColor clearColor];
    _tableView.backgroundColor = linen;
    
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
	
    [refreshHeaderView refreshLastUpdatedDate];
    
    // force-decompress the first 10 images
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSArray *stories = [DDGNewsProvider sharedProvider].stories;
        for(int i=0;i<MIN(stories.count, 10);i++)
            [[stories objectAtIndex:i] prefetchAndDecompressImage];
    });
    
    clockView = [[DDGScrollbarClockView alloc] init];
    [self.view addSubview:clockView];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[DDGUnderViewController class]]) {
	    DDGUnderViewController *underVC = [[DDGUnderViewController alloc] initWithStyle:UITableViewStylePlain];
        underVC.homeViewController = self;
        
        self.slidingViewController.underLeftViewController = underVC;
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self.slidingViewController setAnchorRightRevealAmount:200.0]; // TODO: customize?
    
    self.view.layer.shadowOpacity = 0.75f;
    self.view.layer.shadowRadius = 10.0f;
    self.view.layer.shadowColor = [UIColor blackColor].CGColor;
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
    [self repositionClockView];
    [clockView show:YES animated:NO];
    
    DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:[[[_tableView indexPathsForVisibleRows] objectAtIndex:0] row]];
    [clockView updateDate:story.date];
    
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
    if(!decelerate)
        [clockView show:NO animated:YES];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [clockView show:NO animated:YES];
}

-(void)repositionClockView {
    CGRect f = clockView.frame;
    
    // calculate the center of the scroll bar. the scroll bar's height is the greater of 34px or the proportion of the content that is visible
    CGFloat scrollProgress = _tableView.contentOffset.y / (_tableView.contentSize.height - _tableView.bounds.size.height);
    CGFloat scrollbarHeight = MAX(36.0, self.tableView.bounds.size.height / _tableView.contentSize.height);
    CGFloat scrollbarCenter = scrollProgress*(_tableView.bounds.size.height - scrollbarHeight) + (scrollbarHeight/2.0);
    
    scrollbarCenter = MAX(scrollbarCenter, (f.size.height/2) + 5);
    scrollbarCenter = MIN(scrollbarCenter, _tableView.bounds.size.height - ((f.size.height/2) + 5));
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) {
        // for retina screens, round to the nearest half pixel
        scrollbarCenter = round(scrollbarCenter*2)/2.0;
    } else {
        scrollbarCenter = round(scrollbarCenter);
    }
    
    // add 44px to compensate for the title bar, and another 1px to make it look right
    f.origin.y = 44 + scrollbarCenter - (f.size.height / 2);
    f.origin.x = _tableView.bounds.size.width - (f.size.width+15);
    clockView.frame = f;
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

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
    
    // because we want the search bar to stay in place, we need to do custom animation here instead of relying on UINavigationController.
    
    [clockView show:NO animated:NO];
    [UIView animateWithDuration:0.3 animations:^{
        _tableView.transform = CGAffineTransformMakeScale(2, 2);
        _tableView.alpha = 0;
    } completion:^(BOOL finished) {
        _tableView.transform = CGAffineTransformIdentity;
        [self.navigationController pushViewController:webVC animated:NO];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DDGNewsProvider sharedProvider].stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *TwoLineCellIdentifier = @"TwoLineTopicCell";
	static NSString *OneLineCellIdentifier = @"OneLineTopicCell";
    static UIColor *CellOverlayPatternColor;
    if(!CellOverlayPatternColor)
        CellOverlayPatternColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"topic_cell_background.png"]];

    DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:indexPath.row];
    
    NSString *cellID = nil;
    if([story.title sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(tv.bounds.size.width, 60) lineBreakMode:UILineBreakModeWordWrap].height < 19)
        cellID = OneLineCellIdentifier;
    else
        cellID = TwoLineCellIdentifier;

    
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:cellID owner:self options:nil];
        cell = _loadedCell;
        self.loadedCell = nil;
        
        [[cell.contentView viewWithTag:100] setBackgroundColor:linen];
        
        UIView *overlayImageView = (UIImageView *)[cell.contentView viewWithTag:400];
        overlayImageView.backgroundColor = CellOverlayPatternColor;
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:200];
	label.text = story.title;
    if([[DDGCache objectForKey:story.storyID inCache:@"readStories"] boolValue])
        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    else
        label.textColor = [UIColor whiteColor];
    
    // load article image
    UIImageView *articleImageView = (UIImageView *)[cell.contentView viewWithTag:100];
    [articleImageView setContentMode:UIViewContentModeScaleAspectFill];
    [story loadImageIntoView:articleImageView];
    // load site favicon image
    UIImageView *faviconImageView = (UIImageView *)[cell.contentView viewWithTag:300];
    if(story.feed)
        faviconImageView.image = [DDGCache objectForKey:story.feed inCache:@"sourceImages"];
    else
        faviconImageView.image = nil;
        
	return cell;
}

#pragma  mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:indexPath.row];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // mark the story as read
        [DDGCache setObject:@(YES) forKey:story.storyID inCache:@"readStories"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5]; // wait for the animation to complete
        });
    });

    NSString *escapedStoryURL = [story.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self loadQueryOrURL:escapedStoryURL];
}

#pragma mark - Loading popular stories

// downloads stories asynchronously
-(void)beginDownloadingStories {
    isRefreshing = YES;
    
    [[DDGNewsProvider sharedProvider] downloadSourcesFinished:^{        
        [[DDGNewsProvider sharedProvider] downloadStoriesInTableView:self.tableView finished:^{
            isRefreshing = NO;
            [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        }];
        
    }];
}

@end
