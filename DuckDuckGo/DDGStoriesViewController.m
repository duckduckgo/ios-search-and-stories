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
#import "DDGPanGestureRecognizer.h"
#import "DDGStory.h"
#import "DDGStoryFeed.h"
#import "DDGStoryCell.h"
#import "NSArray+ConcurrentIteration.h"
#import "DDGHistoryProvider.h"
#import "DDGBookmarksProvider.h"
#import "SVProgressHUD.h"
#import "AFNetworking.h"
#import "DDGActivityViewController.h"
#import "DDGStoryFetcher.h"
#import "DDGSafariActivity.h"
#import "DDGActivityItemProvider.h"
#import <CoreImage/CoreImage.h>

NSString *const DDGLastViewedStoryKey = @"last_story";

NSTimeInterval const DDGMinimumRefreshInterval = 30;

NSInteger const DDGLargeImageViewTag = 1;
NSInteger const DDGSmallImageViewTag = 2;

@interface DDGStoriesViewController () {
    BOOL isRefreshing;
    EGORefreshTableHeaderView *refreshHeaderView;
    CIContext *_blurContext;
}
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSOperationQueue *imageDecompressionQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, strong) NSIndexPath *swipeViewIndexPath;
@property (nonatomic, strong) DDGPanGestureRecognizer *panLeftGestureRecognizer;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *swipeView;
@property (nonatomic, weak) IBOutlet UIButton *swipeViewSaveButton;
@property (nonatomic, weak) IBOutlet UIButton *swipeViewSafariButton;
@property (nonatomic, weak) IBOutlet UIButton *swipeViewShareButton;
@property (nonatomic, readwrite, weak) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong) DDGStoryFeed *sourceFilter;
@property (nonatomic, strong) NSCache *decompressedImages;
@property (nonatomic, strong) NSMutableSet *enqueuedDecompressionOperations;
@property (nonatomic, strong) DDGStoryFetcher *storyFetcher;
@property (nonatomic, strong) DDGHistoryProvider *historyProvider;
@end

@implementation DDGStoriesViewController

#pragma mark - Memory Management

- (id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = NSLocalizedString(@"Stories", @"View controller title: Stories");
        self.searchHandler = searchHandler;
        self.managedObjectContext = managedObjectContext;
        
        //Create the context where the blur is going on.
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject: [NSNull null] forKey: kCIContextWorkingColorSpace];
        _blurContext = [CIContext contextWithEAGLContext:eaglContext options:options];
    }
    return self;
}

- (void)dealloc
{
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:DDGSlideOverMenuWillAppearNotification
                                                  object:nil];
}

- (DDGHistoryProvider *)historyProvider {
    if (nil == _historyProvider) {
        _historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
    }
    
    return _historyProvider;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.decompressedImages removeAllObjects];
    if (nil == self.view) {
        [self.imageDownloadQueue cancelAllOperations];
        [self.enqueuedDownloadOperations removeAllObjects];
        [self.imageDecompressionQueue cancelAllOperations];
        [self.enqueuedDecompressionOperations removeAllObjects];
    }
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

#pragma mark - No Stories

- (void)showNoStoriesView {
    if (nil == self.noStoriesView) {
        [[NSBundle mainBundle] loadNibNamed:@"NoStoriesView" owner:self options:nil];
        UIImageView *largeImageView = (UIImageView *)[self.noStoriesView viewWithTag:DDGLargeImageViewTag];
        largeImageView.tintColor = [UIColor whiteColor];
        largeImageView.image = [[UIImage imageNamed:@"NoFavorites"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *smallImageView = (UIImageView *)[self.noStoriesView viewWithTag:DDGSmallImageViewTag];
        smallImageView.tintColor = RGBA(245.0f, 203.0f, 196.0f, 1.0f);
        smallImageView.image = [[UIImage imageNamed:@"inline_actions-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    [UIView animateWithDuration:0 animations:^{
        [self.tableView removeFromSuperview];
        self.noStoriesView.frame = self.view.bounds;
        [self.view addSubview:self.noStoriesView];
    }];
}

- (void)hideNoStoriesView {
    if (nil == self.tableView.superview) {
        [UIView animateWithDuration:0 animations:^{
            [self.noStoriesView removeFromSuperview];
            self.noStoriesView = nil;
            self.tableView.frame = self.view.bounds;
            [self.view addSubview:self.tableView];
        }];        
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor duckNoContentColor];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 220.0f;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    self.fetchedResultsController = [self fetchedResultsController:[[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey]];
    
    [self prepareUpcomingCellContent];
    
    if (!self.savedStoriesOnly && refreshHeaderView == nil) {
		refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		refreshHeaderView.backgroundColor = [UIColor duckRed];
        refreshHeaderView.delegate = self;
		[self.tableView addSubview:refreshHeaderView];
        [refreshHeaderView refreshLastUpdatedDate];
	}
	
    [refreshHeaderView refreshLastUpdatedDate];
        
    //    // force-decompress the first 10 images
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    //        NSArray *stories = self.stories;
    //        for(int i=0;i<MIN(stories.count, 10);i++)
    //            [[stories objectAtIndex:i] prefetchAndDecompressImage];
    //    });
        
    DDGPanGestureRecognizer* panLeftGestureRecognizer = [[DDGPanGestureRecognizer alloc] initWithTarget:self action:@selector(panLeft:)];
    panLeftGestureRecognizer.maximumNumberOfTouches = 1;
    
    self.panLeftGestureRecognizer = panLeftGestureRecognizer;
    [[self.slideOverMenuController panGesture] requireGestureRecognizerToFail:panLeftGestureRecognizer];
    
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 2;
    queue.name = @"DDG Watercooler Image Download Queue";
    self.imageDownloadQueue = queue;
    
    NSOperationQueue *decompressionQueue = [NSOperationQueue new];
    decompressionQueue.name = @"DDG Watercooler Image Decompression Queue";
    self.imageDecompressionQueue = decompressionQueue;
    
    NSCache *decompressedImages = [NSCache new];
    [decompressedImages setCountLimit:50];
    [decompressedImages setName:@"com.duckduckgo.mobile.ios.story-image-cache"];
    self.decompressedImages = decompressedImages;
    
    self.enqueuedDownloadOperations = [NSMutableSet new];
    self.enqueuedDecompressionOperations = [NSMutableSet set];    
}

- (void)viewDidUnload {
    [self setSwipeView:nil];
    [super viewDidUnload];
    
    self.decompressedImages = nil;
    
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
    [self.imageDecompressionQueue cancelAllOperations];
    self.imageDecompressionQueue = nil;
    self.enqueuedDownloadOperations = nil;
    self.enqueuedDecompressionOperations = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:DDGSlideOverMenuWillAppearNotification
                                                  object:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNumber *lastStoryID = [[NSUserDefaults standardUserDefaults] objectForKey:DDGLastViewedStoryKey];
    if (nil != lastStoryID) {
        NSArray *stories = self.fetchedResultsController.fetchedObjects;
        NSArray *storyIDs = [stories valueForKey:@"id"];
        NSInteger index = [storyIDs indexOfObject:lastStoryID];
        if (index != NSNotFound) {
            [self focusOnStory:[stories objectAtIndex:index] animated:NO];
        }
    }
    
    if (!self.savedStoriesOnly) {
        if ([self shouldRefresh]) {
            [self refresh:YES];
        }
    } else if ([self.fetchedResultsController.fetchedObjects count] == 0) {
        [self showNoStoriesView];
    }
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(slidingViewUnderLeftWillAppear:)
                                                 name:DDGSlideOverMenuWillAppearNotification
                                               object:nil];
    
    [self.tableView addGestureRecognizer:self.panLeftGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:DDGSlideOverMenuWillAppearNotification
                                                  object:nil];
    
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

#pragma mark - Filtering

#ifndef __clang_analyzer__
- (IBAction)filter:(id)sender {
    
    void (^completion)() = ^() {
        DDGStory *story = nil;
        
        if ([sender isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)sender;
            CGPoint point = [button convertPoint:button.bounds.origin toView:self.tableView];
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
            story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
        
        if (nil != self.sourceFilter) {
            self.sourceFilter = nil;
        } else if ([sender isKindOfClass:[UIButton class]]) {
            self.sourceFilter = story.feed;
        }

        NSPredicate *predicate = nil;
        if (nil != self.sourceFilter)
            predicate = [NSPredicate predicateWithFormat:@"feed == %@", self.sourceFilter];

        NSArray *oldStories = [self.fetchedResultsController fetchedObjects];
        
        [NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];
        self.fetchedResultsController.delegate = nil;
        self.fetchedResultsController = nil;
        
        NSDate *feedDate = [[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey];
        self.fetchedResultsController = [self fetchedResultsController:feedDate];
        
        NSArray *newStories = [self.fetchedResultsController fetchedObjects];
        
        [self replaceStories:oldStories withStories:newStories focusOnStory:story];
    };
    
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:completion];
    else
        completion();
}
#endif

-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[newStories count]];
    
    for(int i=0;i<newStories.count;i++) {
        DDGStory *story = [newStories objectAtIndex:i];
        NSString *storyID = story.id;
        
        BOOL matchFound = NO;
        for(DDGStory *oldStory in oldStories) {
            if([storyID isEqualToString:[oldStory id]]) {
                matchFound = YES;
                break;
            }
        }
        
        if(!matchFound)
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    return [indexPaths copy];
}

- (NSInteger)replaceStories:(NSArray *)oldStories withStories:(NSArray *)newStories focusOnStory:(DDGStory *)story {
    
    NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:oldStories];
    NSArray *removedStories = [self indexPathsofStoriesInArray:oldStories andNotArray:newStories];
    NSInteger changes = [addedStories count] + [removedStories count];
    
    // update the table view with added and removed stories
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:addedStories
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteRowsAtIndexPaths:removedStories
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    if (self.savedStoriesOnly && [self.fetchedResultsController.fetchedObjects count] == 0) {
        [self showNoStoriesView];
    } else {
        [self hideNoStoriesView];
    }
    
    [self focusOnStory:story animated:YES];
    
    return changes;
}


#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed
{
    [self.slideOverMenuController showMenu];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL
{
    [(DDGUnderViewController *)[self.slideOverMenuController menuViewController] loadQueryOrURL:queryOrURL];
}

#pragma mark - Swipe View

- (IBAction)openInSafari:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    NSArray *stories = self.fetchedResultsController.fetchedObjects;
    DDGStory *story = [stories objectAtIndex:self.swipeViewIndexPath.row];
    
    
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
        
        NSURL *storyURL = story.URL;
        
        if (nil == storyURL)
            return;
        
        [[UIApplication sharedApplication] openURL:storyURL];
    });
}

- (void)save:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    DDGStory *story = [self.fetchedResultsController objectAtIndexPath:self.swipeViewIndexPath];
    
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:^{
            story.savedValue = !story.savedValue;
            NSManagedObjectContext *context = story.managedObjectContext;
            [context performBlockAndWait:^{
                NSError *error = nil;
                if (![context save:&error])
                    NSLog(@"error: %@", error);
            }];
            NSString *status = story.savedValue ? NSLocalizedString(@"Added", @"Bookmark Activity Confirmation: Saved") : NSLocalizedString(@"Removed", @"Bookmark Activity Confirmation: Unsaved");
            UIImage *image = story.savedValue ? [[UIImage imageNamed:@"FavoriteSolid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : [[UIImage imageNamed:@"UnfavoriteSolid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [SVProgressHUD showImage:image status:status];
        }];
    });    
}

- (void)share:(id)sender {
    if (nil == self.swipeViewIndexPath)
        return;
    
    DDGStory *story = [self.fetchedResultsController objectAtIndexPath:self.swipeViewIndexPath];
    
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:^{
            NSString *shareTitle = story.title;
            NSURL *shareURL = story.URL;
            
            DDGActivityItemProvider *titleProvider = [[DDGActivityItemProvider alloc] initWithPlaceholderItem:[shareURL absoluteString]];
            [titleProvider setItem:[NSString stringWithFormat:@"%@: %@\n\nvia DuckDuckGo for iOS\n", shareTitle, shareURL] forActivityType:UIActivityTypeMail];
            
            DDGSafariActivityItem *urlItem = [DDGSafariActivityItem safariActivityItemWithURL:shareURL];            
            NSArray *items = @[titleProvider, urlItem];
            
            DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:items applicationActivities:@[]];
            [self presentViewController:avc animated:YES completion:NULL];
        }];
    });
}

- (void)slidingViewUnderLeftWillAppear:(NSNotification *)notification {
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DDGLastViewedStoryKey];
}

- (void)hideSwipeViewForIndexPath:(NSIndexPath *)indexPath completion:(void (^)())completion {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    self.swipeViewIndexPath = nil;
    
    UIView *swipeView = self.swipeView;
    self.swipeView = nil;
    
    [UIView animateWithDuration:0.1
                     animations:^{
                         cell.contentView.frame = swipeView.frame;
                     } completion:^(BOOL finished) {
                         [swipeView removeFromSuperview];
                         if (NULL != completion)
                             completion();
                     }];
    
    [[self.slideOverMenuController panGesture] setEnabled:YES];
}

- (void)insertSwipeViewForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        UIView *behindView = cell.contentView;
        CGRect swipeFrame = behindView.frame;
        if (!self.swipeView) {
            [[NSBundle mainBundle] loadNibNamed:@"HomeSwipeView" owner:self options:nil];
        }
        [self.swipeView setTintColor:[UIColor whiteColor]];
        DDGStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        BOOL saved = story.savedValue;
        NSString *imageName = (saved) ? @"Unfavorite" : @"Favorite";
        [self.swipeViewSafariButton setImage:[[UIImage imageNamed:@"Safari"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                    forState:UIControlStateNormal];
        [self.swipeViewSaveButton setImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                  forState:UIControlStateNormal];
        [self.swipeViewShareButton setImage:[[UIImage imageNamed:@"ShareSwipe"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                                   forState:UIControlStateNormal];
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

- (void)panLeft:(DDGPanGestureRecognizer *)recognizer {
    
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
            
            [[self.slideOverMenuController panGesture] setEnabled:NO];
            
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

- (void)prepareUpcomingCellContent {
    NSArray *stories = [self.fetchedResultsController fetchedObjects];
    NSInteger count = [stories count];
    
    NSInteger lowestIndex = count;
    NSInteger highestIndex = 0;
    
    for (NSIndexPath *indexPath in [self.tableView indexPathsForVisibleRows]) {
        lowestIndex = MIN(lowestIndex, indexPath.row);
        highestIndex = MAX(highestIndex, indexPath.row);
    }
    
    lowestIndex = MAX(0, lowestIndex-2);
    highestIndex = MIN(count, highestIndex+3);
    
    for (NSInteger i = lowestIndex; i<highestIndex; i++) {
        DDGStory *story = [stories objectAtIndex:i];
        UIImage *decompressedImage = [self.decompressedImages objectForKey:story.id];
        
        if (nil == decompressedImage) {
            if (story.isImageDownloaded) {
                [self decompressAndDisplayImageForStory:story];
            } else  {
                [self.storyFetcher downloadImageForStory:story];
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (nil != self.swipeViewIndexPath)
        [self hideSwipeViewForIndexPath:self.swipeViewIndexPath completion:NULL];
    
    if(scrollView.contentOffset.y <= 0) {
        [refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
    
    [self prepareUpcomingCellContent];
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
    [self refresh:NO];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
    return isRefreshing;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
    return [[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey];;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGStoryCell *cell = [tv dequeueReusableCellWithIdentifier:DDGStoryCellIdentifier];
    if (!cell) {
        cell = [DDGStoryCell new];
    }
    [self configureCell:cell atIndexPath:indexPath];
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
    DDGStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];

    story.readValue = YES;
    
    [[NSUserDefaults standardUserDefaults] setObject:story.id forKey:DDGLastViewedStoryKey];
    
    int readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    [self.searchHandler loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
    
    [self.historyProvider logStory:story];
    
    [theTableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Loading popular stories

- (BOOL)shouldRefresh
{
    NSDate *lastAttempt = (NSDate *)[[NSUserDefaults standardUserDefaults] objectForKey:DDGLastRefreshAttemptKey];
    if (lastAttempt) {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:lastAttempt];
        return (timeInterval > DDGMinimumRefreshInterval);
    }
    return YES;
}

- (void)decompressAndDisplayImageForStory:(DDGStory *)story;
{
    if (nil == story.image)
        return;
    
    NSString *storyID = story.id;
    
    if ([self.enqueuedDecompressionOperations containsObject:storyID])
        return;
    
    __weak DDGStoriesViewController *weakSelf = self;
    
    void (^completionBlock)() = ^() {
        NSIndexPath *indexPath = [weakSelf.fetchedResultsController indexPathForObject:story];
        if (nil != indexPath) {
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    };
    
    UIImage *image = story.image;
    
    if (nil == image)
        completionBlock();
    else {
        [self.enqueuedDecompressionOperations addObject:storyID];
        [self.imageDecompressionQueue addOperationWithBlock:^{
            //Draw the received image in a graphics context.
            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
            [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
            UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            //We're drawing the blurred image here too, but this is a shared OpenGLES graphics context.
            /*
            if (!story.blurredImage) {
                CIImage *imageToBlur = [CIImage imageWithCGImage:decompressed.CGImage];
                
                CGAffineTransform transform = CGAffineTransformIdentity;
                CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
                [clampFilter setValue:imageToBlur forKey:@"inputImage"];
                [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
                
                CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
                [blurFilter setValue:clampFilter.outputImage forKey:@"inputImage"];
                [blurFilter setValue:@10 forKey:@"inputRadius"];
                
                CGImageRef filteredImage = [_blurContext createCGImage:blurFilter.outputImage fromRect:[imageToBlur extent]];
                story.blurredImage = [UIImage imageWithCGImage:filteredImage];
                CGImageRelease(filteredImage);
            }
             */
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf.decompressedImages setObject:decompressed forKey:storyID];
            }];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf.enqueuedDecompressionOperations removeObject:storyID];
                completionBlock();
            }];
        }];
    }
}

- (void)focusOnStory:(DDGStory *)story animated:(BOOL)animated {
    if (nil != story) {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:story];
        if (nil != indexPath)
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:animated];
    }
}

- (DDGStoryFetcher *)storyFetcher {
    if (nil == _storyFetcher)
        _storyFetcher = [[DDGStoryFetcher alloc] initWithParentManagedObjectContext:self.managedObjectContext];
    
    return _storyFetcher;
}

- (void)refresh:(BOOL)includeSources
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:DDGLastRefreshAttemptKey];
    if (includeSources) {
        [self refreshSources];
    } else {
        [self refreshStories];
    }
}

- (void)refreshSources {
    if (!self.storyFetcher.isRefreshing) {
        __weak DDGStoriesViewController *weakSelf = self;
        [self.storyFetcher refreshSources:^(NSDate *feedDate){
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStoryFeed entityName]];
            NSPredicate *iconPredicate = [NSPredicate predicateWithFormat:@"imageDownloaded == %@", @(NO)];
            [request setPredicate:iconPredicate];
            NSError *error = nil;
            NSArray *feeds = [weakSelf.managedObjectContext executeFetchRequest:request error:&error];
            if (nil == feeds)
                NSLog(@"failed to fetch story feeds. Error: %@", error);
            
            for (DDGStoryFeed *feed in feeds)
                if (!feed.imageDownloadedValue)
                    [weakSelf.storyFetcher downloadIconForFeed:feed];
            
            [weakSelf refreshStories];
        }];
    }
}

- (void)refreshStories {
    if (!self.storyFetcher.isRefreshing) {
        
        __block NSArray *oldStories = nil;        
        __weak DDGStoriesViewController *weakSelf = self;
        
        void (^willSave)() = ^() {
            oldStories = [self.fetchedResultsController fetchedObjects];
            
            [NSFetchedResultsController deleteCacheWithName:weakSelf.fetchedResultsController.cacheName];
            weakSelf.fetchedResultsController.delegate = nil;
        };
        
        void (^completion)(NSDate *lastFetchDate) = ^(NSDate *feedDate) {
            NSArray *oldStories = [weakSelf.fetchedResultsController fetchedObjects];

            weakSelf.fetchedResultsController = nil;
            weakSelf.fetchedResultsController = [self fetchedResultsController:feedDate];
            
            NSArray *newStories = [self.fetchedResultsController fetchedObjects];
            NSInteger changes = [weakSelf replaceStories:oldStories withStories:newStories focusOnStory:nil];
            [weakSelf prepareUpcomingCellContent];
            
            isRefreshing = NO;
            [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:weakSelf.tableView];
            
            if(changes > 0 && [[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingQuackOnRefresh]) {
                SystemSoundID quack;
                NSURL *url = [[NSBundle mainBundle] URLForResource:@"quack" withExtension:@"wav"];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &quack);
                AudioServicesPlaySystemSound(quack);
            }
        };
        
        [self.storyFetcher refreshStories:willSave completion:completion];
    }
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController:(NSDate *)feedDate
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [DDGStory entityInManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSMutableArray *predicates = [NSMutableArray array];
    
    int readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    if (readabilityMode == DDGReadabilityModeOnExclusive && !self.savedStoriesOnly)
        [predicates addObject:[NSPredicate predicateWithFormat:@"articleURLString.length > 0"]];
    
    if (nil != self.sourceFilter)
        [predicates addObject:[NSPredicate predicateWithFormat:@"feed == %@", self.sourceFilter]];
    if (self.savedStoriesOnly)
        [predicates addObject:[NSPredicate predicateWithFormat:@"saved == %@", @(YES)]];
    if (nil != feedDate && !self.savedStoriesOnly)
        [predicates addObject:[NSPredicate predicateWithFormat:@"feedDate == %@", feedDate]];    
    if ([predicates count] > 0)
        [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
//    NSLog(@"feedDate: %@", feedDate);
//    for (DDGStory *story in [_fetchedResultsController fetchedObjects]) {
//        NSLog(@"story.feedDate: %@ (isEqual: %i)", story.feedDate, [feedDate isEqual:story.feedDate]);
//    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (self.savedStoriesOnly && [self.fetchedResultsController.fetchedObjects count] == 0)
                [self performSelector:@selector(showNoStoriesView) withObject:nil afterDelay:0.2];
            
        }
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(DDGStoryCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)configureCell:(DDGStoryCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    DDGStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.displaysDropShadow = (indexPath.row == ([self.tableView numberOfRowsInSection:indexPath.section] - 1));
    cell.displaysInnerShadow = (indexPath.row != 0);
    cell.title = story.title;
    cell.read = story.readValue;
    if (story.feed) {
        cell.favicon = [story.feed image];
    }
    UIImage *image = [self.decompressedImages objectForKey:story.id];
    if (image) {
        cell.image = image;
    } else {
        if (story.isImageDownloaded) {
            [self decompressAndDisplayImageForStory:story];
        } else {
            [self.storyFetcher downloadImageForStory:story];
        }
    }
}


@end
