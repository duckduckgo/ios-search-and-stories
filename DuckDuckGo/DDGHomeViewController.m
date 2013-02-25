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
#import "DDGHistoryProvider.h"
#import "DDGNewsProvider.h"
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
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSOperationQueue *imageDecompressionQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, strong) NSIndexPath *swipeViewIndexPath;
@property (nonatomic, strong) UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
@property (nonatomic, copy) NSArray *stories;
@end

@implementation DDGHomeViewController

- (void)dealloc
{
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
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
    
    self.stories = [[DDGNewsProvider sharedProvider] filteredStories];
    
//    // force-decompress the first 10 images
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{        
//        NSArray *stories = self.stories;
//        for(int i=0;i<MIN(stories.count, 10);i++)
//            [[stories objectAtIndex:i] prefetchAndDecompressImage];
//    });
    
    DDGUnderViewController *underVC = [[DDGUnderViewController alloc] initWithHomeViewController:self];
    self.slidingViewController.underLeftViewController = underVC;
    [self.slidingViewController setAnchorRightRevealAmount:255.0];
    
    // this one time, we have to do add the gesture recognizer manually; underVC only does it for us when the view is loaded through the menu
    [underVC configureViewController:self];
    
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    
    self.leftSwipeGestureRecognizer = leftSwipeGestureRecognizer;
    [self.slidingViewController.panGesture requireGestureRecognizerToFail:leftSwipeGestureRecognizer];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 2;
    queue.name = @"DDG Watercooler Image Download Queue";
    self.imageDownloadQueue = queue;

    NSOperationQueue *decompressionQueue = [NSOperationQueue new];
    decompressionQueue.name = @"DDG Watercooler Image Decompression Queue";
    self.imageDecompressionQueue = decompressionQueue;
    
    self.enqueuedDownloadOperations = [NSMutableSet new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (nil == self.view) {
        [self.imageDownloadQueue cancelAllOperations];
        self.imageDownloadQueue = nil;
        self.enqueuedDownloadOperations = nil;
    }
}

// Called when a left swipe occurred
- (void)swipeLeft:(UISwipeGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    DDGStory *story = [self.stories objectAtIndex:indexPath.row];
    NSURL *storyURL = [NSURL URLWithString:story.url];
    
    if (nil != storyURL) {
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:storyURL];
        NSString *imageName = (bookmarked ? @"swipe-un-save" : @"swipe-save");
        UIImage *image = [UIImage imageNamed:imageName];
        [self.swipeViewSaveButton setImage:image forState:UIControlStateNormal];
    }
    
    [self showSwipeViewForIndexPath:indexPath];
}

- (void)viewDidUnload {
    [self setSwipeView:nil];
    [super viewDidUnload];
    
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
    self.enqueuedDownloadOperations = nil;
    
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
    
    [self.imageDownloadQueue cancelAllOperations];
    [self.enqueuedDownloadOperations removeAllObjects];
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

- (IBAction)openInSafari:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    DDGStory *story = [self.stories objectAtIndex:self.swipeViewIndexPath.row];
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
    
    NSURL *storyURL = [NSURL URLWithString:story.url];
    
    if (nil == storyURL)
        return;
    
    [[UIApplication sharedApplication] openURL:storyURL];    
}

- (void)save:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;

    DDGStory *story = [self.stories objectAtIndex:self.swipeViewIndexPath.row];
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];

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
    
    DDGStory *story = [self.stories objectAtIndex:self.swipeViewIndexPath.row];
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:^{
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

- (IBAction)filter:(id)sender {

    DDGNewsProvider *newsProvider = [DDGNewsProvider sharedProvider];
    
    if (nil != newsProvider.sourceFilter) {
        newsProvider.sourceFilter = nil;
    } else if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        CGPoint point = [button convertPoint:button.bounds.origin toView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        DDGStory *story = [self.stories objectAtIndex:indexPath.row];
        newsProvider.sourceFilter = story.feed;
    }
    
    [self replaceStories:newsProvider.filteredStories];
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

#pragma mark - DDGNewsProviderDelegate

- (void)newsProviderDidRefreshStories:(DDGNewsProvider *)newsProvider {
    
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
    return self.stories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *TwoLineCellIdentifier = @"TwoLineTopicCell";
	static NSString *OneLineCellIdentifier = @"OneLineTopicCell";

    DDGStory *story = [self.stories objectAtIndex:indexPath.row];
    
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
  
    if (nil != story.decompressedImage) {
        cell.imageView.image = story.decompressedImage;
    } else {
        cell.imageView.image = nil;
        if (story.isImageDownloaded) {
            [self decompressAndDisplayImageForStory:story];
        } else  {
            [self loadImageForStory:story];
        }
    }
    
    UIImage *image = nil;
    if(story.feed)
        image = [DDGCache objectForKey:story.feed inCache:@"sourceImages"];    
    [cell.faviconButton setImage:image forState:UIControlStateNormal];
    
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
    DDGStory *story = [self.stories objectAtIndex:indexPath.row];
    
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

- (void)loadImageForStory:(DDGStory *)story {
    NSURL *imageURL = story.imageURL;
    if (!story.imageDownloaded && ![self.enqueuedDownloadOperations containsObject:imageURL]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSData *responseData = (NSData *)responseObject;
            [story writeImageData:responseData completion:^(BOOL success) {
                if (success)
                    [self decompressAndDisplayImageForStory:story];
            }];
            [self.enqueuedDownloadOperations removeObject:imageURL];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self.enqueuedDownloadOperations removeObject:imageURL];
        }];
        
        [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            [self.enqueuedDownloadOperations removeObject:imageURL];
        }];
        
        [self.enqueuedDownloadOperations addObject:imageURL];
        [self.imageDownloadQueue addOperation:operation];
    }
}

- (void)decompressAndDisplayImageForStory:(DDGStory *)story {
    if (nil == story.image)
        return;
    
    void (^completionBlock)(UIImage *) = ^(UIImage *decompressedImage) {
        story.decompressedImage = decompressedImage;
        NSUInteger row = [self.stories indexOfObject:story];
        if (row != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    };
    
    [self decompressImage:story.image completionBlock:completionBlock];
}

- (void)decompressImage:(UIImage *)image completionBlock:(void (^)(UIImage *decompressedImage))completionBlock {
    
    if (nil == image)
        completionBlock(nil);
    else {
        [self.imageDecompressionQueue addOperationWithBlock:^{
            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
            [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
            UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionBlock(decompressed);
            }];
        }];
    }
}

- (void)downloadStoryImages {
    NSArray *stories = [[self stories] copy];
    for (DDGStory *story in stories) {
        [self loadImageForStory:story];
    }
}

// this method ignores stories from custom sources
-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    for(int i=0;i<newStories.count;i++) {
        NSString *storyID = [[newStories objectAtIndex:i] storyID];
        
        BOOL matchFound = NO;
        for(DDGStory *oldStory in oldStories) {
            if([storyID isEqualToString:[oldStory storyID]]) {
                matchFound = YES;
                break;
            }
        }
        
        if(!matchFound)
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    return [indexPaths copy];
}

- (void)replaceStories:(NSArray *)newStories {
    
    NSArray *oldStories = [self.stories copy];
    self.stories = newStories;
    
    NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:oldStories];
    NSArray *removedStories = [self indexPathsofStoriesInArray:oldStories andNotArray:newStories];
    
    // delete old story images
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for(NSIndexPath *indexPath in removedStories) {
            DDGStory *removedStory = [oldStories objectAtIndex:indexPath.row];
            [removedStory deleteImage];
        }
    });
        
    // update the table view with added and removed stories
    [self.tableView beginUpdates];    
    [self.tableView insertRowsAtIndexPaths:addedStories
                     withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteRowsAtIndexPaths:removedStories
                     withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

// downloads stories asynchronously
-(void)beginDownloadingStories {
    isRefreshing = YES;

    DDGNewsProvider *newsProvider = [DDGNewsProvider sharedProvider];    
    
    [newsProvider downloadSourcesFinished:^{
        [newsProvider downloadStoriesFinished:^{
            [self replaceStories:newsProvider.filteredStories];
            [self downloadStoryImages];
            isRefreshing = NO;
            [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        }];
    }];
}

@end
