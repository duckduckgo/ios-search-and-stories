//
//  DDGStoriesViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import "DDGStoriesViewController.h"
#import "DDGUnderViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGPanLeftGestureRecognizer.h"
#import "DDGStory.h"
#import "DDGStoryCell.h"
#import "NSArray+ConcurrentIteration.h"
#import "ECSlidingViewController.h"
#import "DDGCache.h"
#import "DDGHistoryProvider.h"
#import "DDGNewsProvider.h"
#import "DDGBookmarksProvider.h"
#import "SVProgressHUD.h"
#import "AFNetworking.h"
#import "DDGActivityViewController.h"

NSString * const DDGLastViewedStoryKey = @"last_story";

@interface DDGStoriesViewController () {
    BOOL isRefreshing;
    UIImageView *topShadow;
    EGORefreshTableHeaderView *refreshHeaderView;    
}
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSOperationQueue *imageDecompressionQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, strong) NSIndexPath *swipeViewIndexPath;
@property (nonatomic, strong) DDGPanLeftGestureRecognizer *panLeftGestureRecognizer;
@property (nonatomic, copy) NSArray *stories;
@property (nonatomic, strong) IBOutlet DDGStoryCell *loadedCell;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *swipeView;
@property (weak, nonatomic) IBOutlet UIButton *swipeViewSaveButton;
@end

@implementation DDGStoriesViewController

#pragma mark - Memory Management

- (void)dealloc
{
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:self.slidingViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    if (nil == self.view) {
        [self.imageDownloadQueue cancelAllOperations];
        self.imageDownloadQueue = nil;
        self.enqueuedDownloadOperations = nil;
    }
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.separatorColor = [UIColor clearColor];
    tableView.backgroundColor = [UIColor colorWithRed:0.204 green:0.220 blue:0.251 alpha:1.000];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 135.0;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
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
        
    DDGPanLeftGestureRecognizer* panLeftGestureRecognizer = [[DDGPanLeftGestureRecognizer alloc] initWithTarget:self action:@selector(panLeft:)];
    panLeftGestureRecognizer.maximumNumberOfTouches = 1;
    
    self.panLeftGestureRecognizer = panLeftGestureRecognizer;
    [self.slidingViewController.panGesture requireGestureRecognizerToFail:panLeftGestureRecognizer];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 2;
    queue.name = @"DDG Watercooler Image Download Queue";
    self.imageDownloadQueue = queue;
    
    NSOperationQueue *decompressionQueue = [NSOperationQueue new];
    decompressionQueue.name = @"DDG Watercooler Image Decompression Queue";
    self.imageDecompressionQueue = decompressionQueue;
    
    self.enqueuedDownloadOperations = [NSMutableSet new];
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
    
    NSNumber *lastStoryID = [[NSUserDefaults standardUserDefaults] objectForKey:DDGLastViewedStoryKey];
    if (nil != lastStoryID) {
        NSArray *storyIDs = [self.stories valueForKey:@"storyID"];
        NSInteger index = [storyIDs indexOfObject:lastStoryID];
        if (index != NSNotFound) {
            [self focusOnStory:[self.stories objectAtIndex:index] animated:NO];
        }
    }
    
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
    
    [self.tableView addGestureRecognizer:self.panLeftGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:self.slidingViewController];
    
    [self.tableView removeGestureRecognizer:self.panLeftGestureRecognizer];
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

#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:queryOrURL];
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
    NSURL *storyURL = [NSURL URLWithString:story.url];
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:^{
        if (nil == storyURL)
            return;
        
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:storyURL];
        if(bookmarked)
            [[DDGBookmarksProvider sharedProvider] unbookmarkPageWithURL:storyURL];
        else
            [[DDGBookmarksProvider sharedProvider] bookmarkPageWithTitle:story.title feed:story.feed URL:storyURL];
        
        [SVProgressHUD showSuccessWithStatus:(bookmarked ? @"Unsaved!" : @"Saved!")];
    }];
}

- (void)share:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    DDGStory *story = [self.stories objectAtIndex:self.swipeViewIndexPath.row];
    
    [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:^{
        NSString *shareTitle = story.title;
        NSURL *shareURL = [NSURL URLWithString:story.url];
        DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:@[shareTitle, shareURL]];
        [self presentViewController:avc animated:YES completion:NULL];
    }];
}

- (void)slidingViewUnderLeftWillAppear:(NSNotification *)notification {
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DDGLastViewedStoryKey];
}

- (void)hideSwipeViewForIndexPath:(NSIndexPath *)indexPath completion:(void (^)())completion {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    self.swipeViewIndexPath = nil;
    [UIView animateWithDuration:0.1
                     animations:^{
                         cell.contentView.frame = self.swipeView.frame;
                     } completion:^(BOOL finished) {
                         if (nil == self.swipeViewIndexPath)
                             [self.swipeView removeFromSuperview];
                         if (NULL != completion)
                             completion();
                     }];
}

- (void)insertSwipeViewForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (nil != cell) {
        UIView *behindView = cell.contentView;
        CGRect swipeFrame = behindView.frame;
        
        if (nil == self.swipeView)
            [[NSBundle mainBundle] loadNibNamed:@"HomeSwipeView" owner:self options:nil];
        
        
        DDGStory *story = [self.stories objectAtIndex:indexPath.row];
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:[NSURL URLWithString:story.url]];
        
        NSString *imageName = (bookmarked) ? @"swipe-un-save" : @"swipe-save";
        [self.swipeViewSaveButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        
        self.swipeView.frame = swipeFrame;
        [behindView.superview insertSubview:self.swipeView belowSubview:behindView];
        self.swipeViewIndexPath = indexPath;
    }
    
}

- (void)showSwipeViewForIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    void(^completion)() = ^() {
        if (nil != cell) {
            UIView *behindView = cell.contentView;
            CGRect swipeFrame = behindView.frame;
            [self insertSwipeViewForIndexPath:indexPath];
            [UIView animateWithDuration:0.2
                             animations:^{
                                 behindView.frame = CGRectMake(swipeFrame.origin.x - swipeFrame.size.width,
                                                               swipeFrame.origin.y,
                                                               swipeFrame.size.width,
                                                               swipeFrame.size.height);
                             }];
        }
    };
    
    if (nil != self.swipeViewIndexPath) {
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:completion];
    } else {
        completion();
    }
}

// Called when a left swipe occurred

- (void)panLeft:(DDGPanLeftGestureRecognizer *)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateFailed) {
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded
               || recognizer.state == UIGestureRecognizerStateCancelled) {
        
        if (nil != self.swipeViewIndexPath) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.swipeViewIndexPath];
            CGPoint origin = self.swipeView.frame.origin;
            CGRect contentFrame = cell.contentView.frame;
            CGFloat offset = origin.x - contentFrame.origin.x;
            CGFloat percent = offset / contentFrame.size.width;
            
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            
            if (velocity.x < 0 && percent > 0.25) {
                CGFloat distanceRemaining = contentFrame.size.width - offset;
                CGFloat duration = MIN(distanceRemaining / abs(velocity.x), 0.4);
                [UIView animateWithDuration:duration
                                 animations:^{
                                     cell.contentView.frame = CGRectMake(origin.x - contentFrame.size.width,
                                                                         contentFrame.origin.y,
                                                                         contentFrame.size.width,
                                                                         contentFrame.size.height);
                                 }];
                
            } else {
                [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
            }
        }
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [recognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        
        if (nil != self.swipeViewIndexPath
            && ![self.swipeViewIndexPath isEqual:indexPath]) {
            [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
        }
        
        if (nil == self.swipeViewIndexPath) {
            [self insertSwipeViewForIndexPath:indexPath];
        }
        
        DDGStoryCell *cell = (DDGStoryCell *)[self.tableView cellForRowAtIndexPath:self.swipeViewIndexPath];
        CGPoint translation = [recognizer translationInView:recognizer.view];
        
        CGPoint center = cell.contentView.center;
        cell.contentView.center = CGPointMake(center.x + translation.x,
                                              center.y);
        
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
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
    
    void (^completion)() = ^() {
        DDGNewsProvider *newsProvider = [DDGNewsProvider sharedProvider];
        DDGStory *story = nil;
        
        if ([sender isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)sender;
            CGPoint point = [button convertPoint:button.bounds.origin toView:self.tableView];
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
            story = [self.stories objectAtIndex:indexPath.row];
        }
        
        if (nil != newsProvider.sourceFilter) {
            newsProvider.sourceFilter = nil;
        } else if ([sender isKindOfClass:[UIButton class]]) {
            newsProvider.sourceFilter = story.feed;
        }
        
        [self replaceStories:newsProvider.filteredStories focusOnStory:story];
    };
    
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:completion];
    else
        completion();
}


#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    [self beginDownloadingStories];
    
    if([[DDGCache objectForKey:DDGSettingQuackOnRefresh inCache:DDGSettingsCacheName] boolValue]) {
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
    if([story.title sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(tv.bounds.size.width-38, 60) lineBreakMode:NSLineBreakByWordWrapping].height < 19)
        cellID = OneLineCellIdentifier;
    else
        cellID = TwoLineCellIdentifier;
    
    
	DDGStoryCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil)
	{
        [[NSBundle mainBundle] loadNibNamed:cellID owner:self options:nil];
        cell = _loadedCell;
        self.loadedCell = nil;
        
        cell.imageView.backgroundColor = self.tableView.backgroundColor;
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
            [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    });
    
    [[NSUserDefaults standardUserDefaults] setObject:story.storyID forKey:DDGLastViewedStoryKey];
    
    BOOL showInReadView = [[DDGCache objectForKey:DDGSettingStoriesReadView inCache:DDGSettingsCacheName] boolValue];
    if (showInReadView) {
        [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadStory:story];
    } else {
        NSString *escapedStoryURL = [story.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:escapedStoryURL];
        
        [[DDGHistoryProvider sharedProvider] logHistoryItem:@{@"text": story.title, @"url": story.url, @"feed": story.feed, @"kind": @"feed"}];
    }
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
    
    void (^completionBlock)() = ^() {
        NSUInteger row = [self.stories indexOfObject:story];
        if (row != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    };
    
    UIImage *image = story.image;
    
    if (nil == image)
        completionBlock();
    else {
        [self.imageDecompressionQueue addOperationWithBlock:^{
            if (nil == story.decompressedImage) {
                UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
                [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
                UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    story.decompressedImage = decompressed;
                }];
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionBlock();
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

- (void)focusOnStory:(DDGStory *)story animated:(BOOL)animated {
    if (nil != story) {
        NSUInteger row = [self.stories indexOfObject:story];
        if (row != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:animated];
        }
    }
}

- (void)replaceStories:(NSArray *)newStories focusOnStory:(DDGStory *)story {
    
    NSArray *oldStories = [self.stories copy];
    self.stories = newStories;
    
    NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:oldStories];
    NSArray *removedStories = [self indexPathsofStoriesInArray:oldStories andNotArray:newStories];
    
    // delete old story images
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for(NSIndexPath *indexPath in removedStories) {
            DDGStory *removedStory = [oldStories objectAtIndex:indexPath.row];
            [removedStory deleteImage];
            [removedStory deleteHTML];
        }
    });
    
    // update the table view with added and removed stories
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:addedStories
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteRowsAtIndexPaths:removedStories
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    [self focusOnStory:story animated:YES];
}

// downloads stories asynchronously
-(void)beginDownloadingStories {
    isRefreshing = YES;
    
    DDGNewsProvider *newsProvider = [DDGNewsProvider sharedProvider];
    
    [newsProvider downloadSourcesFinished:^{
        [newsProvider downloadStoriesFinished:^{
            [self replaceStories:newsProvider.filteredStories focusOnStory:nil];
            [self downloadStoryImages];
            isRefreshing = NO;
            [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
        }];
    }];
}


@end
