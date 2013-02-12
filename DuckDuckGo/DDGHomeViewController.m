//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGHomeViewController.h"
#import "AFNetworking.h"
#import "DDGCache.h"
#import <QuartzCore/QuartzCore.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGNewsProvider.h"
#import "DDGHistoryProvider.h"
#import "DDGChooseSourcesViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGStory.h"
#import "ECSlidingViewController.h"
#import "DDGUnderViewController.h"
#import "DDGBookmarksProvider.h"
#import "SVProgressHUD.h"
#import "SHK.h"
#import "DDGStoryCell.h"

@interface DDGHomeViewController ()
@property (nonatomic, strong) NSIndexPath *swipeViewIndexPath;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
@end

@implementation DDGHomeViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:self.slidingViewController];
}

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
    
    DDGUnderViewController *underVC = [[DDGUnderViewController alloc] initWithHomeViewController:self];
    self.slidingViewController.underLeftViewController = underVC;
    [self.slidingViewController setAnchorRightRevealAmount:255.0];
    
    // this one time, we have to do add the gesture recognizer manually; underVC only does it for us when the view is loaded through the menu
    [underVC configureViewController:self];
    
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    
    self.leftSwipeGestureRecognizer = leftSwipeGestureRecognizer;
    [self.slidingViewController.panGesture requireGestureRecognizerToFail:leftSwipeGestureRecognizer];
}

// Called when a left swipe occurred
- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:indexPath.row];
    NSURL *storyURL = [NSURL URLWithString:story.url];
    
    if (nil != storyURL) {
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:storyURL];
        NSString *title = (bookmarked ? @"Unsave" : @"Save");
        [self.swipeViewSaveButton setTitle:title forState:UIControlStateNormal];
    }
    
    [self showSwipeViewForIndexPath:indexPath];
}

- (void)viewDidUnload {
    [self setSwipeView:nil];
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:self.slidingViewController];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slidingViewUnderLeftWillAppear:)
                                                 name:ECSlidingViewUnderLeftWillAppear
                                               object:self.slidingViewController];
    
    [self.tableView addGestureRecognizer:self.leftSwipeGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:self.slidingViewController];
    
    [self.tableView removeGestureRecognizer:self.leftSwipeGestureRecognizer];
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

#pragma mark - Swipe View

- (void)save:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];

    DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:self.swipeViewIndexPath.row];
    NSURL *storyURL = [NSURL URLWithString:story.url];
    
    if (nil == storyURL)
        return;
    
    BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:storyURL];
    if(bookmarked)
        [[DDGBookmarksProvider sharedProvider] unbookmarkPageWithURL:storyURL];
    else
        [[DDGBookmarksProvider sharedProvider] bookmarkPageWithTitle:story.title feed:story.feed URL:storyURL];
    
    [SVProgressHUD showSuccessWithStatus:(bookmarked ? @"Unsaved!" : @"Saved!")];
}

- (void)share:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:^{
        DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:self.swipeViewIndexPath.row];
        
        SHKItem *item = [SHKItem URL:[NSURL URLWithString:story.url] title:story.title contentType:SHKURLContentTypeWebpage];
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
        [SHK setRootViewController:self];
        [actionSheet showInView:self.view];        
    }];
}

- (void)slidingViewUnderLeftWillAppear:(NSNotification *)notification {
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
}

- (void)hideSwipeViewForIndexPath:(NSIndexPath *)indexPath completion:(void (^)())completion {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                     animations:^{
                         cell.imageView.frame = self.swipeView.frame;
                     } completion:^(BOOL finished) {
                         [self.swipeView removeFromSuperview];
                         self.swipeViewIndexPath = nil;
                         if (NULL != completion)
                             completion();
                     }];
}

- (void)showSwipeViewForIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.swipeViewIndexPath isEqual:indexPath])
        return;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    void(^completion)() = ^() {
        if (nil != cell) {
            UIView *behindView = cell.imageView;
            CGRect swipeFrame = behindView.frame;
            
            if (nil == self.swipeView)
                [[NSBundle mainBundle] loadNibNamed:@"HomeSwipeView" owner:self options:nil];
            
            self.swipeView.frame = swipeFrame;
            [behindView.superview insertSubview:self.swipeView belowSubview:behindView];
            [UIView animateWithDuration:0.2
                             animations:^{
                                 behindView.frame = CGRectMake(swipeFrame.origin.x - swipeFrame.size.width,
                                                             swipeFrame.origin.y,
                                                             swipeFrame.size.width,
                                                             swipeFrame.size.height);
                             }];
            self.swipeViewIndexPath = indexPath;
        }
    };
    
    if (nil != self.swipeViewIndexPath) {
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:completion];
    } else {
        completion();
    }
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];    
    
    if(scrollView.contentOffset.y <= 0) {
        [refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];

        CGRect f = topShadow.frame;
        f.origin.y = scrollView.contentOffset.y;
        topShadow.frame = f;
        
        [_tableView insertSubview:topShadow atIndex:0];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    [self beginDownloadingStories];
    
    if([[DDGCache objectForKey:@"quack" inCache:@"settings"] boolValue]) {
        SystemSoundID quack;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"quack" ofType:@"wav"];
        NSURL *url = [NSURL URLWithString:path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &quack);
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
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {    
    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:queryOrURL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [DDGNewsProvider sharedProvider].stories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *TwoLineCellIdentifier = @"TwoLineTopicCell";
	static NSString *OneLineCellIdentifier = @"OneLineTopicCell";

    DDGStory *story = [[DDGNewsProvider sharedProvider].stories objectAtIndex:indexPath.row];
    
    NSString *cellID = nil;
    if([story.title sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(tv.bounds.size.width-38, 60) lineBreakMode:UILineBreakModeWordWrap].height < 19)
        cellID = OneLineCellIdentifier;
    else
        cellID = TwoLineCellIdentifier;

    
	DDGStoryCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil)
	{
        [[NSBundle mainBundle] loadNibNamed:cellID owner:self options:nil];
        cell = _loadedCell;
        self.loadedCell = nil;
        
        cell.imageView.backgroundColor = linen;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.overlayImageView.image = [UIImage imageNamed:@"topic_cell_background.png"];
    }
    
    cell.textLabel.text = story.title;
    
    if([[DDGCache objectForKey:story.storyID inCache:@"readStories"] boolValue])
        cell.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    else
        cell.textLabel.textColor = [UIColor whiteColor];
    
    [story loadImageIntoView:cell.imageView];
    
    if(story.feed)
        cell.faviconImageView.image = [DDGCache objectForKey:story.feed inCache:@"sourceImages"];
    else
        cell.faviconImageView.image = nil;
        
	return cell;
}

#pragma  mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (nil != self.swipeViewIndexPath) {
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
        return nil;
    }
    
    return indexPath;
}

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
    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:escapedStoryURL];

	[[DDGHistoryProvider sharedProvider] logHistoryItem:@{@"text": story.title, @"url": story.url, @"feed": story.feed, @"kind": @"feed"}];
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
