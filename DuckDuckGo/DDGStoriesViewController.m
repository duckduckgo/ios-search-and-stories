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
#import "DDGStoryFeed.h"
#import "DDGStoryCell.h"
#import "NSArray+ConcurrentIteration.h"
#import "ECSlidingViewController.h"
#import "DDGHistoryProvider.h"
#import "DDGBookmarksProvider.h"
#import "SVProgressHUD.h"
#import "AFNetworking.h"
#import "DDGActivityViewController.h"
#import "DDGStoryFetcher.h"
#import "DDGSafariActivity.h"
#import "DDGActivityItemProvider.h"

NSString * const DDGLastViewedStoryKey = @"last_story";

@interface DDGStoriesViewController () {
    BOOL isRefreshing;
    UIImageView *topShadow;
    EGORefreshTableHeaderView *refreshHeaderView;    
}
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSOperationQueue *imageDecompressionQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, strong) NSIndexPath *swipeViewIndexPath;
@property (nonatomic, strong) DDGPanLeftGestureRecognizer *panLeftGestureRecognizer;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *swipeView;
@property (weak, nonatomic) IBOutlet UIButton *swipeViewSaveButton;
@property (nonatomic, readwrite, weak) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong) DDGStoryFeed *sourceFilter;
@property (nonatomic, strong) NSMutableDictionary *decompressedImages;
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
    }
    return self;
}

- (void)dealloc
{
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ECSlidingViewUnderLeftWillAppear
                                                  object:self.slidingViewController];
}

- (DDGHistoryProvider *)historyProvider {
    if (nil == _historyProvider) {
        _historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
    }
    
    return _historyProvider;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    self.decompressedImages = nil;
    
    if (nil == self.view) {
        [self.imageDownloadQueue cancelAllOperations];
        self.imageDownloadQueue = nil;
        self.enqueuedDownloadOperations = nil;
        [self.imageDecompressionQueue cancelAllOperations];
        self.imageDecompressionQueue = nil;
        self.enqueuedDecompressionOperations = nil;
    }
}

#pragma mark - No Stories

- (void)showNoStoriesView {
    if (nil == self.noStoriesView)
        [[NSBundle mainBundle] loadNibNamed:@"NoStoriesView" owner:self options:nil];
    
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
    tableView.backgroundColor = [UIColor colorWithRed:0.204 green:0.220 blue:0.251 alpha:1.000];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 135.0;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    self.fetchedResultsController = [self fetchedResultsController:[[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey]];
    
    [self prepareUpcomingCellContent];
    
    topShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table_view_shadow_top.png"]];
    topShadow.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 5.0);
    topShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    // shadow gets added to table view in scrollViewDidScroll
    
    if (!self.savedStoriesOnly && refreshHeaderView == nil) {
		refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
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
    
    self.decompressedImages = [NSMutableDictionary dictionaryWithCapacity:50];
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
        NSArray *stories = self.fetchedResultsController.fetchedObjects;
        NSArray *storyIDs = [stories valueForKey:@"id"];
        NSInteger index = [storyIDs indexOfObject:lastStoryID];
        if (index != NSNotFound) {
            [self focusOnStory:[stories objectAtIndex:index] animated:NO];
        }
    }
    
    if (!self.savedStoriesOnly)
        [self refreshSources];
    else if ([self.fetchedResultsController.fetchedObjects count] == 0)
        [self showNoStoriesView];
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

- (UIImage *)searchControllerBackButtonIconDDG {
    return [UIImage imageNamed:@"button_menu_glyph_home"];
}

#pragma mark - Filtering

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

- (void)replaceStories:(NSArray *)oldStories withStories:(NSArray *)newStories focusOnStory:(DDGStory *)story {
    
    NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:oldStories];
    NSArray *removedStories = [self indexPathsofStoriesInArray:oldStories andNotArray:newStories];
    
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
            
            BOOL saved = story.savedValue;
            story.savedValue = !story.savedValue;
            
            NSManagedObjectContext *context = story.managedObjectContext;
            [context performBlock:^{
                NSError *error = nil;
                if (![context save:&error])
                    NSLog(@"error: %@", error);
            }];
            
            [SVProgressHUD showSuccessWithStatus:(saved ? @"Unsaved!" : @"Saved!")];
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
    
    [self.slidingViewController.panGesture setEnabled:YES];
}

- (void)insertSwipeViewForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (nil != cell) {
        UIView *behindView = cell.contentView;
        CGRect swipeFrame = behindView.frame;
        
        if (nil == self.swipeView)
            [[NSBundle mainBundle] loadNibNamed:@"HomeSwipeView" owner:self options:nil];
        
        DDGStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
        BOOL saved = story.savedValue;
        
        NSString *imageName = (saved) ? @"swipe-un-save" : @"swipe-save";
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
            
            [self.slidingViewController.panGesture setEnabled:NO];
            
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
        
        CGRect f = topShadow.frame;
        f.origin.y = scrollView.contentOffset.y;
        topShadow.frame = f;
        
        [_tableView insertSubview:topShadow atIndex:0];
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
    [self refreshStories];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingQuackOnRefresh]) {
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
	static NSString *CellIdentifier = @"TopicCell";
    
	DDGStoryCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
	{
        cell = [[DDGStoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.imageView.backgroundColor = self.tableView.backgroundColor;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
        cell.overlayImageView.image = [UIImage imageNamed:@"topic_cell_background.png"];
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
    
    [self.searchHandler loadStory:story readabilityMode:[[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingStoriesReadView]];
    
    [self.historyProvider logStory:story];
    
    [theTableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Loading popular stories

- (void)decompressAndDisplayImageForStory:(DDGStory *)story {
    if (nil == story.image)
        return;
    
    NSString *storyID = story.id;
    
    if ([self.enqueuedDecompressionOperations containsObject:storyID])
        return;
    
    void (^completionBlock)() = ^() {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:story];
        if (nil != indexPath) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    };
    
    UIImage *image = story.image;
    
    if (nil == image)
        completionBlock();
    else {
        [self.enqueuedDecompressionOperations addObject:storyID];
        [self.imageDecompressionQueue addOperationWithBlock:^{
            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
            [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
            UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.decompressedImages setObject:decompressed forKey:storyID];
            }];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.enqueuedDecompressionOperations removeObject:storyID];
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

- (void)refreshSources {
    if (!self.storyFetcher.isRefreshing) {
        [self.storyFetcher refreshSources:^(NSDate *feedDate){
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStoryFeed entityName]];
            NSPredicate *iconPredicate = [NSPredicate predicateWithFormat:@"imageDownloaded == %@", @(NO)];
            [request setPredicate:iconPredicate];
            NSError *error = nil;
            NSArray *feeds = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (nil == feeds)
                NSLog(@"failed to fetch story feeds. Error: %@", error);
            
            for (DDGStoryFeed *feed in feeds)
                if (!feed.imageDownloadedValue)
                    [self.storyFetcher downloadIconForFeed:feed];
            
            [self refreshStories];
        }];
    }
}

- (void)refreshStories {
    if (!self.storyFetcher.isRefreshing) {
        
        __block NSArray *oldStories = nil;
        
        void (^willSave)() = ^() {
            oldStories = [self.fetchedResultsController fetchedObjects];
            
            [NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];
            self.fetchedResultsController.delegate = nil;
        };
        
        void (^completion)(NSDate *lastFetchDate) = ^(NSDate *feedDate) {
            NSArray *oldStories = [self.fetchedResultsController fetchedObjects];

            self.fetchedResultsController = nil;            
            self.fetchedResultsController = [self fetchedResultsController:feedDate];
            
            NSArray *newStories = [self.fetchedResultsController fetchedObjects];
            [self replaceStories:oldStories withStories:newStories focusOnStory:nil];
            
            [self prepareUpcomingCellContent];
            
            isRefreshing = NO;
            [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
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
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    DDGStory *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    DDGStoryCell *storyCell = ([cell isKindOfClass:[DDGStoryCell class]]) ? (DDGStoryCell *) cell : nil;
    
    cell.textLabel.text = story.title;
    [cell setNeedsLayout];
    
    if(story.readValue)
        cell.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    else
        cell.textLabel.textColor = [UIColor whiteColor];    
    
    UIImage *image = nil;
    if(story.feed)
        image = story.feed.image;
    [storyCell.faviconButton setImage:image forState:UIControlStateNormal];
    
    UIImage *decompressedImage = [self.decompressedImages objectForKey:story.id];
    
    if (nil != decompressedImage) {
        cell.imageView.image = decompressedImage;
    } else {
        cell.imageView.image = nil;
        if (story.isImageDownloaded) {
            [self decompressAndDisplayImageForStory:story];
        } else  {
            [self.storyFetcher downloadImageForStory:story];
        }
    }
    
}


@end
