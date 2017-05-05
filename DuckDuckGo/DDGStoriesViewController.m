//
//  DDGStoriesViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 06/03/2013.
//
//

#import "DDGStoriesViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGStory.h"
#import "DDGStoryFeed.h"
#import "DDGStoryCell.h"
#import "NSArray+ConcurrentIteration.h"
#import "DDGHistoryProvider.h"
#import "DDGBookmarksProvider.h"
#import "AFNetworking.h"
#import "DDGActivityViewController.h"
#import "DDGStoryFetcher.h"
#import "DDGSafariActivity.h"
#import "DDGActivityItemProvider.h"
#import "DDGNoContentViewController.h"
#import <CoreImage/CoreImage.h>
#import "DDGTableView.h"
#import "DDGCollectionView.h"
#import "DDGStoriesLayout.h"
#import "DDGConstraintHelper.h"
#import "DuckDuckGo-Swift.h"

NSTimeInterval const DDGMinimumRefreshInterval = 30;

NSInteger const DDGLargeImageViewTag = 1;

NSString* const DDGOnboardingBannerStoryCellIdentifier = @"MiniOnboardingCell";

@class DDGStoriesLayout;

@interface DDGStoriesViewController () {
    CIContext *_blurContext;
    NSMutableArray* _sectionChanges;
    NSMutableArray* _objectChanges;
    BOOL _processCoreDataUpdates;
}

@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSOperationQueue *imageDownloadQueue;
@property (nonatomic, strong) NSOperationQueue *imageDecompressionQueue;
@property (nonatomic, strong) NSMutableSet *enqueuedDownloadOperations;
@property (nonatomic, strong) IBOutlet UICollectionView *storyView;
@property (readonly) NSString* lastRefreshDefaultsKey;
@property (nonatomic, strong) NSDate* lastRefreshAttempt;


@property (nonatomic, readwrite, weak) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong) DDGStoryFeed *sourceFilter;
@property (nonatomic, strong) NSString* categoryFilter;
@property (nonatomic, strong) NSMutableDictionary *decompressedImages;
@property (nonatomic, strong) NSMutableSet *enqueuedDecompressionOperations;
@property (nonatomic, strong) DDGStoryFetcher *storyFetcher;
@property (nonatomic, strong) DDGHistoryProvider *historyProvider;
@property (nonatomic, strong) UIRefreshControl* refreshControl;
@property (nonatomic, strong) DDGNoContentViewController* noContentView;
@property (nonatomic, strong) DDGStoriesLayout* storiesLayout;
@property (nonatomic, strong) NSNumber* lastStoryIDViewed;
@property (nonatomic, assign) BOOL ignoreCoreDataUpdates;
@property (nonatomic, strong) MiniOnboardingViewController* onboarding;

@end



#pragma mark DDGStoriesViewController


@implementation DDGStoriesViewController



- (id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = NSLocalizedString(@"Stories", @"View controller title: Stories");
        self.searchHandler = searchHandler;
        self.managedObjectContext = managedObjectContext;
        
        _processCoreDataUpdates = FALSE;
        _sectionChanges = [NSMutableArray new];
        _objectChanges = [NSMutableArray new];
        
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // clear the cache, except for the currently visible items
    NSMutableDictionary *cachedImages = [NSMutableDictionary new];
    NSArray *indexPaths = [self.storyView indexPathsForVisibleItems];
    for (NSIndexPath *indexPath in indexPaths) {
        DDGStory *story = [self fetchedStoryAtIndexPath:indexPath];
        if (story) {
            UIImage *image = [self.decompressedImages objectForKey:story.cacheKey];
            if (image) {
                [cachedImages setObject:image forKey:story.cacheKey];
            }
        }
    }
    [self.decompressedImages removeAllObjects];
    [self.decompressedImages addEntriesFromDictionary:cachedImages];
    
    if (nil == self.view) {
        [self.imageDownloadQueue cancelAllOperations];
        [self.enqueuedDownloadOperations removeAllObjects];
        [self.imageDecompressionQueue cancelAllOperations];
        [self.enqueuedDecompressionOperations removeAllObjects];
    }
}

- (DDGHistoryProvider *)historyProvider {
    if (nil == _historyProvider) {
        _historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
    }
    
    return _historyProvider;
}

- (void)reenableScrollsToTop {
    self.storyView.scrollsToTop = YES;
}


-(BOOL)showsOnboarding {
    return self.onboarding!=nil;
}

-(void)setShowsOnboarding:(BOOL)showOnboarding {
    BOOL showingOnboarding = self.onboarding!=nil;
    if(showOnboarding==showingOnboarding) return;
    
    if(showOnboarding) {
        self.onboarding = [MiniOnboardingViewController loadFromStoryboard];
        self.onboarding.dismissHandler = ^{
            [NSUserDefaults.standardUserDefaults setBool:FALSE forKey:kDDGMiniOnboardingName];
            [NSUserDefaults.standardUserDefaults synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDDGMiniOnboardingName object:nil];
        };
        [self addChildViewController:self.onboarding];
    } else {
        self.onboarding.dismissHandler = nil;
        [self.onboarding removeFromParentViewController];
        self.onboarding = nil;
    }
    [self.storyView reloadData];
    [self.view setNeedsLayout];
}

#pragma mark - No Stories

- (void)setShowNoContent:(BOOL)showNoContent {
    if(showNoContent==self.noContentView.view.hidden) {
        [UIView animateWithDuration:0 animations:^{
            self.storyView.hidden = showNoContent;
            self.noContentView.view.hidden = !showNoContent;
        }];
    }
}



#pragma mark - DDGStoryDelegate

-(NSUInteger)storiesListMode {
    return self.storiesMode;
}

-(void)shareStory:(DDGStory*)story fromView:(UIView*)storySource;
{
    NSURL *shareURL = story.URL;
    
    NSString* shareString = [NSString stringWithFormat:NSLocalizedString(@"%@\n\nvia DuckDuckGo for iOS\n\n", @"Story title followed by message saying this was shared from DuckDuckGo for iOS: %@\n\nvia DuckDuckGo for iOS\n\n"), story.title];
    
    NSArray *items = @[shareString, shareURL];
    
    DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:items
                                                                        applicationActivities:@[  ]];
    if ( [avc respondsToSelector:@selector(popoverPresentationController)] ) {
        // iOS8
        CGRect sourceRect = storySource.frame;
        sourceRect.origin = CGPointMake(0, 0);
        avc.popoverPresentationController.sourceView = storySource;
        avc.popoverPresentationController.sourceRect = sourceRect;
    }
    
    [self presentViewController:avc animated:YES completion:NULL];
}


// Removed....
-(void)toggleStorySaved:(DDGStory*)story
{
 
    NSManagedObjectContext *context = story.managedObjectContext;
    [context performBlock:^{
        story.savedValue = !story.savedValue;
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"error: %@", error);
        } else {
            if (self.storiesMode == DDGStoriesListModeFavorites) {
                [self.storyView reloadData];
            }
        }
        
    }];
}


-(void)openStoryInBrowser:(DDGStory*)story
{
    NSURL *storyURL = story.URL;
    if (nil == storyURL)
        return;
    
    [[UIApplication sharedApplication] openURL:storyURL];
}

-(void)removeHistoryItem:(DDGHistoryItem*)historyItem
{
    NSManagedObjectContext *context = historyItem.managedObjectContext;
    [context performBlock:^{
        DDGStory* story = historyItem.story;
        if(story) {
            story.readValue = NO;
        }
        [context deleteObject:historyItem];
        
        NSError *error = nil;
        if (![context save:&error])
            NSLog(@"error: %@", error);
    }];
}

-(void)toggleCategoryPressed:(NSString*)categoryName onStory:(DDGStory*)story
{
    if (self.categoryFilter==nil) {
        self.categoryFilter = categoryName;
    } else {
        self.categoryFilter = nil;
    }
    
    NSDate *feedDate = [[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey];
    NSArray *oldStories = [self fetchedStories];
    [NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
    [self fetchedResultsController:feedDate];
    
    NSArray *newStories = [self fetchedStories];
    [self replaceStories:oldStories withStories:newStories focusOnStory:story];
}

-(void)restoreScrollPositionAnimated:(BOOL)animated {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    id firstStoryID = [defaults objectForKey:[self lastViewedDefaultsKeyPrefix]];
    if(firstStoryID) {
        CGFloat offset = [defaults doubleForKey:[[self lastViewedDefaultsKeyPrefix] stringByAppendingString:@".offset"]];
        //if(offset<0) offset = 0.0;
        
        NSArray *stories = [self fetchedStories];
        NSArray *storyIDs = [stories valueForKey:@"id"];
        NSInteger index = [storyIDs indexOfObject:firstStoryID];
        if(index!=NSNotFound) {
            NSIndexPath* cellPath = [NSIndexPath indexPathForItem:index inSection:0];
            CGPoint storyOffset = [self.storiesLayout frameForStoryAtIndexPath:cellPath].origin;
            [self.storyView setContentOffset:CGPointMake(0, storyOffset.y - offset) animated:animated];
        }
        
    }
}

-(void)saveScrollPosition {
    NSArray* visibleStoryCells = [self.storyView visibleCells];
    DDGStory* firstStory = nil;
    NSIndexPath* firstStoryIndex = nil;
    CGFloat firstStoryScreenPosition = 0.0f;
    CGPoint scrollOffset = self.storyView.contentOffset;
    
    // get the first story (and its index + bounds) that is fully visible on the screen
    for(DDGStoryCell* visibleCell in visibleStoryCells) {
        NSIndexPath* cellPath = [self.storyView indexPathForCell:visibleCell];
        if(!cellPath) continue;
        CGRect cellRect = [self.storiesLayout frameForStoryAtIndexPath:cellPath];
        CGFloat screenPosition = cellRect.origin.y-scrollOffset.y;
        if([visibleCell isKindOfClass:DDGStoryCell.class] && (firstStory==nil || ( screenPosition >= 0 && screenPosition < firstStoryScreenPosition ) )) {
            firstStory = visibleCell.story;
            firstStoryIndex = cellPath;
            firstStoryScreenPosition = screenPosition;
        }
    }
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if(firstStory && firstStoryIndex.row!=0) { // save the first visible story, unless we're at the top of the list
        [defaults setObject:firstStory.id forKey:[self lastViewedDefaultsKeyPrefix]];
        [defaults setObject:[NSNumber numberWithDouble:firstStoryScreenPosition] forKey:[[self lastViewedDefaultsKeyPrefix] stringByAppendingString:@".offset"]];
    } else {
        [defaults removeObjectForKey:[self lastViewedDefaultsKeyPrefix]];
        [defaults removeObjectForKey:[[self lastViewedDefaultsKeyPrefix] stringByAppendingString:@".offset"]];
    }
}


-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.lastStoryIDViewed = [[NSUserDefaults standardUserDefaults] objectForKey:[self lastViewedDefaultsKeyPrefix]];
    
    self.storiesLayout = [[DDGStoriesLayout alloc] init];
    self.storiesLayout.storiesController = self;
    UICollectionView* storyView = [[DDGCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.storiesLayout];
    storyView.canCancelContentTouches = TRUE;
    storyView.backgroundColor = [UIColor duckStoriesBackground];
    storyView.dataSource = self;
    storyView.delegate = self;
    
    [storyView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [storyView registerClass:DDGStoryCell.class forCellWithReuseIdentifier:DDGStoryCellIdentifier];
    [storyView registerClass:OnboardingMiniCollectionViewCell.class
  forSupplementaryViewOfKind:DDGOnboardingBannerViewKindID
         withReuseIdentifier:DDGOnboardingBannerStoryCellIdentifier];

    
    self.storyView = storyView;
    
    if(self.storiesMode==DDGStoriesListModeNormal) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        self.refreshControl.tintColor = [UIColor duckRefreshColor];
        [storyView addSubview:self.refreshControl];
        [self.refreshControl addTarget:self action:@selector(refreshManually) forControlEvents:UIControlEventValueChanged];
        storyView.backgroundView = self.refreshControl;

        // show the mini banner and register for updates to further show or hide it
        [self updateOnboardingState];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateOnboardingState)
                                                     name:kDDGMiniOnboardingName object:nil];
    }
    
    self.noContentView = [[DDGNoContentViewController alloc] init];
    [self.noContentView view]; // force the xib to load
    if(self.storiesMode==DDGStoriesListModeFavorites) {
        self.noContentView.noContentImageview.image = [UIImage imageNamed:@"empty-favorites"];
        self.noContentView.contentTitle = NSLocalizedString(@"No Favorites",
                                                            @"title for the view shown when no favorite searches/urls are found");
        self.noContentView.contentSubtitle = NSLocalizedString(@"Add stories to your favorites, and they will be shown here.",
                                                               @"details text for the view shown when no favorite stories are found");
    } else {
        self.noContentView.noContentImageview.image = [UIImage imageNamed:@"empty-recents"];
        self.noContentView.contentTitle = NSLocalizedString(@"No Recents",
                                                            @"title for the view shown when no favorite searches/urls are found");
        self.noContentView.contentSubtitle = NSLocalizedString(@"Browse stories and search the web, and your recents will be shown here.",
                                                               @"details text for the view shown when no recent stories are found");
    }
    self.noContentView.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.noContentView.view.frame = self.view.bounds;
    
    [self.view addSubview:self.storyView];
    [DDGConstraintHelper pinView:storyView intoView:self.view];
    [self.view addSubview:self.noContentView.view];
    
    _processCoreDataUpdates = FALSE;
    
    
    //    // force-decompress the first 10 images
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    //        NSArray *stories = self.stories;
    //        for(int i=0;i<MIN(stories.count, 10);i++)
    //            [[stories objectAtIndex:i] prefetchAndDecompressImage];
    //    });
        
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 2;
    queue.name = @"DDG Watercooler Image Download Queue";
    self.imageDownloadQueue = queue;
    
    NSOperationQueue *decompressionQueue = [NSOperationQueue new];
    decompressionQueue.name = @"DDG Watercooler Image Decompression Queue";
    self.imageDecompressionQueue = decompressionQueue;
    
    self.decompressedImages = [NSMutableDictionary new];
    
    self.enqueuedDownloadOperations = [NSMutableSet new];
    self.enqueuedDecompressionOperations = [NSMutableSet set];    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.decompressedImages = nil;
    
    [self.imageDownloadQueue cancelAllOperations];
    self.imageDownloadQueue = nil;
    [self.imageDecompressionQueue cancelAllOperations];
    self.imageDecompressionQueue = nil;
    self.enqueuedDownloadOperations = nil;
    self.enqueuedDecompressionOperations = nil;
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self restoreScrollPositionAnimated:animated];
    
    if (self.storiesMode==DDGStoriesListModeNormal) {
        if ([self shouldRefresh]) {
            [self refreshStoriesTriggeredManually:NO includeSources:YES];
        }
    }
    
    [self.searchControllerDDG.homeController registerScrollableContent:self.storyView];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.fetchedResultsController = nil; // force a refresh of the fetchedResultsController
    [self fetchedResultsController:[[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey]];
    [self prepareUpcomingCellContent];
    // if we animated out, animate back in
    if(_storyView.alpha == 0) {
        _storyView.transform = CGAffineTransformMakeScale(2, 2);
        [UIView animateWithDuration:0.3 animations:^{
            _storyView.alpha = 1;
            _storyView.transform = CGAffineTransformIdentity;
        }];
    }
    _processCoreDataUpdates = TRUE;
    [self.storyView reloadData];
    self.showNoContent = [self fetchedStories].count == 0 && self.storiesMode!=DDGStoriesListModeNormal;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self saveScrollPosition];
    
    [super viewWillDisappear:animated];
    
    _processCoreDataUpdates = FALSE;
    [self.imageDownloadQueue cancelAllOperations];
    [self.enqueuedDownloadOperations removeAllObjects];
    self.fetchedResultsController.delegate = nil;
    //self.fetchedResultsController = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    _processCoreDataUpdates = FALSE;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self saveScrollPosition];
    self.storiesLayout.mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.storyView setNeedsLayout];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [self saveScrollPosition];
    // Return YES for supported orientations
	if (IPHONE)
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	else
        return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self restoreScrollPositionAnimated:FALSE];
}

-(void)viewDidLayoutSubviews {
    CGFloat onboardHeight = 0;
    [self updateOnboardingState];
    if(self.showsOnboarding) {
        onboardHeight = self.view.frame.size.width <= 480 ? 210 : 165;
    }
    self.storiesLayout.bannerHeight = onboardHeight;
    
    self.storyView.contentSize = self.storiesLayout.collectionViewContentSize;
    [self.storyView layoutSubviews];
}


-(void)updateOnboardingState {
    BOOL showIt = [NSUserDefaults.standardUserDefaults boolForKey:kDDGMiniOnboardingName defaultValue:TRUE];
    // hide the banner if we're on an iPad or landscape.  In other words, if the width is not "compact"
    showIt &= self.storiesMode==DDGStoriesListModeNormal;
    showIt &= self.view.frame.size.width <= 480;
    self.showsOnboarding = showIt;
}


#pragma mark - Filtering

#ifndef __clang_analyzer__
- (IBAction)filter:(id)sender {
    DDGStory *story = nil;
    
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        CGPoint point = [button convertPoint:button.bounds.origin toView:self.storyView];
        NSIndexPath *indexPath = [self.storyView indexPathForItemAtPoint:point];
        story = [self fetchedStoryAtIndexPath:indexPath];
    }
    
    if (nil != self.sourceFilter) {
        self.sourceFilter = nil;
    } else if ([sender isKindOfClass:[UIButton class]]) {
        self.sourceFilter = story.feed;
    }
    
    NSPredicate *predicate = nil;
    if (nil != self.sourceFilter)
        predicate = [NSPredicate predicateWithFormat:@"feed == %@", self.sourceFilter];
    
    NSArray *oldStories = [self fetchedStories];
    [NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
    
    NSDate *feedDate = [[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey];
    self.fetchedResultsController = [self fetchedResultsController:feedDate];
    
    NSArray *newStories = [self fetchedStories];
    
    [self replaceStories:oldStories withStories:newStories focusOnStory:story];
}
#endif

-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[newStories count]];
    
    for(int i=0; i<newStories.count; i++) {
        DDGStory *story = [newStories objectAtIndex:i];
        NSString *storyID = story.id;
        
        BOOL matchFound = NO;
        for(DDGStory *oldStory in oldStories) {
            if([storyID isEqualToString:[oldStory id]]) {
                matchFound = YES;
                break;
            }
        }
        
        if(!matchFound) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        }
    }
    return [indexPaths copy];
}

- (NSInteger)replaceStories:(NSArray *)oldStories withStories:(NSArray *)newStories focusOnStory:(DDGStory *)story {
    NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:oldStories];
    NSArray *removedStories = [self indexPathsofStoriesInArray:oldStories andNotArray:newStories];
    NSInteger changes = [addedStories count] + [removedStories count];
    
    // update the table view with added and removed stories
    if(removedStories.count!=0 || addedStories.count!=0) {
        [self.storyView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    }
    
    self.showNoContent = [self fetchedStories].count == 0 && self.storiesMode!=DDGStoriesListModeNormal;
    
    [self focusOnStory:story animated:YES];
    
    return changes;
}


-(void)duckGoToTopLevel
{
    if([self collectionView:self.storyView numberOfItemsInSection:0] > 0) {
        [self.storyView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:TRUE];
        if(self.navigationController.viewControllers.count>1) {
            [self.navigationController popToRootViewControllerAnimated:TRUE];
        }
    }
}

#pragma mark - Search handler

-(void)loadQueryOrURL:(NSString *)queryOrURL
{
    [self.searchControllerDDG loadQueryOrURL:queryOrURL];
}

#pragma mark - Swipe View


#pragma mark - Scroll view delegate

- (void)prepareUpcomingCellContent {
    NSArray *stories = [self fetchedStories];
    NSInteger count = [stories count];
    
    NSInteger lowestIndex = count;
    NSInteger highestIndex = 0;
    
    for (NSIndexPath *indexPath in [self.storyView indexPathsForVisibleItems]) {
        lowestIndex = MIN(lowestIndex, indexPath.item);
        highestIndex = MAX(highestIndex, indexPath.item);
    }
    
    lowestIndex = MAX(0, lowestIndex-2);
    highestIndex = MIN(count, highestIndex+3);
    
    for (NSInteger i = lowestIndex; i<highestIndex; i++) {
        DDGStory *story = [stories objectAtIndex:i];
        if([story isEqual:[NSNull null]]) continue;
        UIImage *decompressedImage = [self.decompressedImages objectForKey:story.cacheKey];
        
        if (nil == decompressedImage) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            if (story.isImageDownloaded) {
                [self decompressAndDisplayImageForStoryAtIndexPath:indexPath];
            } else  {
                __weak DDGStoriesViewController *weakSelf = self;
                [self.storyFetcher downloadImageForStory:story completion:^(BOOL success) {
                    [weakSelf.storyView reloadItemsAtIndexPaths:@[indexPath]];
                }];
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Scroll view did scroll is redundant as the collection view cell prepares the cells anyway
    // [self prepareUpcomingCellContent];
}

#pragma mark - collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    return 1; //[[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DDGStoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DDGStoryCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [DDGStoryCell new];
    }
    cell.touchPassthroughView = collectionView;
    cell.mosaicMode = ((DDGStoriesLayout*)self.storyView.collectionViewLayout).mosaicMode;
    cell.storyDelegate = self;
    
    DDGStory* story = nil;
    DDGHistoryItem* historyItem = nil;
    if(self.storiesMode==DDGStoriesListModeRecents) {
        historyItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
        story = historyItem.story;
    } else {
        story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    cell.story = story;
    cell.historyItem = historyItem;
    UIImage *image = [self.decompressedImages objectForKey:story.cacheKey];
    if (image) {
        cell.image = image;
    } else {
        if (story.isImageDownloaded) {
            [self decompressAndDisplayImageForStoryAtIndexPath:indexPath];
        } else {
            __weak typeof(self) weakSelf = self;
            [self.storyFetcher downloadImageForStory:story completion:^(BOOL success) {
                [weakSelf.storyView reloadItemsAtIndexPaths:@[indexPath]];
            }];
        }
    }
    [cell setNeedsLayout];
    return cell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
           atIndexPath:(NSIndexPath *)indexPath
{
    OnboardingMiniCollectionViewCell* cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                withReuseIdentifier:DDGOnboardingBannerStoryCellIdentifier
                                                                                       forIndexPath:indexPath];
    cell.onboarder = self.onboarding;
    return cell;
}


#pragma  mark - collection view delegate

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return TRUE;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Check if a menu has been presented first......
    DDGStoryCell *currentCell = (DDGStoryCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (currentCell.shouldGoToDetail) {
        DDGStory *story = [self fetchedStoryAtIndexPath:indexPath];
        [self saveScrollPosition];
        
        NSInteger readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
        [self.searchHandler loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
        
        [self.historyProvider logStory:story];
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    } else {
        // One hit so do it again.
        currentCell.shouldGoToDetail = YES;
    }
}

#pragma mark - Loading popular stories

- (BOOL)shouldRefresh
{
    return [[NSDate date] timeIntervalSinceDate:self.lastRefreshAttempt] > DDGMinimumRefreshInterval;
}

- (void)decompressAndDisplayImageForStoryAtIndexPath:(NSIndexPath*)indexPath;
{
    DDGStory* story = [self fetchedStoryAtIndexPath:indexPath];
    if (nil == story || nil == story.image || nil == story.cacheKey)
        return;
    
    NSString *cacheKey = story.cacheKey;
    
    if ([self.enqueuedDecompressionOperations containsObject:cacheKey]) {
        // this image is already in the queue for decompression
        return;
    }
    
    __weak DDGStoriesViewController *weakSelf = self;
    
    void (^completionBlock)() = ^() {
        if (nil != indexPath) {
            [weakSelf.storyView reloadItemsAtIndexPaths:@[indexPath]];
        }
    };
    
    UIImage *image = story.image;
    
    if (nil == image) {
        completionBlock();
    } else {
        [self.enqueuedDecompressionOperations addObject:cacheKey];
        [self.imageDecompressionQueue addOperationWithBlock:^{
            //Draw the received image in a graphics context.
            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
            [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
            UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf.decompressedImages setObject:decompressed forKey:cacheKey];
            }];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf.enqueuedDecompressionOperations removeObject:cacheKey];
                completionBlock();
            }];
        }];
    }
}

-(NSString*)storiesModeLabel {
    switch(self.storiesMode) {
        case DDGStoriesListModeFavorites: return @"faves";
        case DDGStoriesListModeNormal: return @"normal";
        case DDGStoriesListModeRecents: return @"recents";
        default: return @"UNKNOWN!";
    }
}

- (void)focusOnStory:(DDGStory *)story animated:(BOOL)animated {
    if (nil != story) {
        NSUInteger itemIndex = [[self fetchedStories] indexOfObject:story];
        if (itemIndex != NSNotFound) {
            [self.storyView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemIndex inSection:0]
                                   atScrollPosition:UICollectionViewScrollPositionNone animated:animated];
        }
    }
}

- (DDGStoryFetcher *)storyFetcher {
    if (nil == _storyFetcher)
        _storyFetcher = [[DDGStoryFetcher alloc] initWithParentManagedObjectContext:self.managedObjectContext];
    
    return _storyFetcher;
}


-(NSString*)lastRefreshDefaultsKey
{
    switch(self.storiesMode) {
        case DDGStoriesListModeNormal:
            return @"lastRefreshAttempt";
        case DDGStoriesListModeFavorites:
            return @"lastRefreshFavorites";
        case DDGStoriesListModeRecents:
            return @"lastRefreshRecents";
        default:
            return @"lastRefreshMisc";
    }
}

-(NSString*)lastViewedDefaultsKey
{
    switch(self.storiesMode) {
        case DDGStoriesListModeNormal:
            return @"last_story.main";
        case DDGStoriesListModeFavorites:
            return @"last_story.fav";
        case DDGStoriesListModeRecents:
            return @"last_story.recent";
        default:
            return @"last_story.other";
    }
}

-(NSString*)lastViewedDefaultsKeyPrefix
{
    switch(self.storiesMode) {
        case DDGStoriesListModeNormal:
            return @"last_story_id.main";
        case DDGStoriesListModeFavorites:
            return @"last_story_id.fav";
        case DDGStoriesListModeRecents:
            return @"last_story_id.recent";
        default:
            return @"last_story_id.other";
    }
}



-(NSDate*)lastRefreshAttempt
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:self.lastRefreshDefaultsKey];
    if(value==nil) return [NSDate dateWithTimeIntervalSince1970:0];
    if([value isKindOfClass:NSDate.class]) return (NSDate*)value;
    return [NSDate dateWithTimeIntervalSince1970:0];
}


-(void)setLastRefreshAttempt:(NSDate*)referenceDate
{
    [[NSUserDefaults standardUserDefaults] setObject:referenceDate forKey:self.lastRefreshDefaultsKey];
}

- (void)refreshStoriesTriggeredManually:(BOOL)manual includeSources:(BOOL)includeSources
{
    self.lastRefreshAttempt = [NSDate date];
    if (includeSources) {
        [self refreshSources:manual];
    } else {
        [self refreshStories:manual];
    }
}

- (void)refreshSources:(BOOL)manual {
    if (!self.storyFetcher.isRefreshing) {
        __weak DDGStoriesViewController *weakSelf = self;
        [self.storyFetcher refreshSources:^(NSDate *feedDate){
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGStoryFeed entityName]];
            NSPredicate *iconPredicate = [NSPredicate predicateWithFormat:@"imageDownloaded == %@", @(NO)];
            [request setPredicate:iconPredicate];
            NSError *error = nil;
            NSArray *feeds = [weakSelf.managedObjectContext executeFetchRequest:request error:&error];
            if (nil == feeds) {
                NSLog(@"failed to fetch story feeds. Error: %@", error);
            }
            
            [weakSelf refreshStories:manual];
        }];
    }
}

- (void)refreshManually {
    [self.refreshControl endRefreshing];
    [self refreshStories:TRUE];
}

- (void)refreshStories:(BOOL)manual {
    if (!self.storyFetcher.isRefreshing) {
        
        __block NSArray *oldStories = nil;        
        DDGStoriesViewController *weakSelf = self;
        
        void (^willSave)() = ^() {
            oldStories = [self fetchedStories];
            
            [NSFetchedResultsController deleteCacheWithName:weakSelf.fetchedResultsController.cacheName];
            weakSelf.fetchedResultsController.delegate = nil;
        };
        
        void (^completion)(NSDate *lastFetchDate) = ^(NSDate *feedDate) {
            NSArray *oldStories = [weakSelf fetchedStories];

            weakSelf.fetchedResultsController = nil;
            [self fetchedResultsController:feedDate];
            
            NSArray *newStories = [self fetchedStories];
            NSInteger changes = [weakSelf replaceStories:oldStories withStories:newStories focusOnStory:nil];
            [weakSelf prepareUpcomingCellContent];
            
            if(changes > 0 && [[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingQuackOnRefresh]) {
                SystemSoundID quack;
                NSURL *url = [[NSBundle mainBundle] URLForResource:@"quack" withExtension:@"wav"];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &quack);
                AudioServicesPlaySystemSound(quack);
            }
            self.showNoContent = [self fetchedStories].count == 0 && self.storiesMode!=DDGStoriesListModeNormal;
        };
        
        [self.storyFetcher refreshStories:willSave completion:completion];
    }
}

#pragma mark - NSFetchedResultsController

-(NSArray*)fetchedStories
{
    NSArray* results = self.fetchedResultsController.fetchedObjects;
    if(self.storiesMode==DDGStoriesListModeRecents) {
        results = [results valueForKey:@"story"]; // the controller returns a list of history items, so extract the stories from them
    }
    return results;
}

- (NSFetchedResultsController *)fetchedResultsController:(NSDate *)feedDate
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSMutableArray *predicates = [NSMutableArray array];
    if(self.storiesMode==DDGStoriesListModeRecents) { // we query the history items list
        [fetchRequest setEntity:[DDGHistoryItem entityInManagedObjectContext:self.managedObjectContext]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"section == %@", DDGHistoryItemSectionNameStories]];
    } else {
        [fetchRequest setEntity:[DDGStory entityInManagedObjectContext:self.managedObjectContext]];
        switch(self.storiesMode) {
            case DDGStoriesListModeFavorites:
                [predicates addObject:[NSPredicate predicateWithFormat:@"saved == %@", @(YES)]];
                break;
            case DDGStoriesListModeNormal:
                if (feedDate) {
                    [predicates addObject:[NSPredicate predicateWithFormat:@"feedDate == %@", feedDate]];
                }
                break;
            default:
                break;
        }
    }
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    if(self.storiesMode!=DDGStoriesListModeRecents) {
        NSInteger readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
        if (readabilityMode == DDGReadabilityModeOnExclusive && self.storiesMode!=DDGStoriesListModeFavorites) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"articleURLString.length > 0"]];
        }
    }
    
    if (nil != self.sourceFilter) {
        NSString* predicateKey = self.storiesMode==DDGStoriesListModeRecents ? @"feed" : @"feed";
        [predicates addObject:[NSPredicate predicateWithFormat:@"%K == %@", predicateKey, self.sourceFilter]];
    }
    
    if (nil != self.categoryFilter) {
        NSString* predicateKey = self.storiesMode==DDGStoriesListModeRecents ? @"story.category" : @"category";
        [predicates addObject:[NSPredicate predicateWithFormat:@"%K == %@", predicateKey, self.categoryFilter]];
    }
    
    if ([predicates count] > 0) {
        [fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    }
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:self.managedObjectContext
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not
        // use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
//    [self.storyView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(!_processCoreDataUpdates) return;
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @[@(sectionIndex)];
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @[@(sectionIndex)];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
    [_sectionChanges addObject:change];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    if(!_processCoreDataUpdates) return;
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if(!_processCoreDataUpdates) return;
    
    if ([_sectionChanges count] > 0) {

        [self.storyView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges) {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type) {
                        case NSFetchedResultsChangeInsert:
                            [self.storyView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.storyView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.storyView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeMove:
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    
    NSMutableArray *indexPathsToReload = [NSMutableArray new];
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0) {
        [self.storyView performBatchUpdates:^{
            for (NSDictionary *change in _objectChanges) {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type) {
                        case NSFetchedResultsChangeInsert:
                            [self.storyView insertItemsAtIndexPaths:@[obj]];
                            // [toInsert addObject:obj];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.storyView deleteItemsAtIndexPaths:@[obj]];
                            // [toDelete addObject:obj];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            // We can't actually run updates from here, only inserts, deletes and moves...
                            [indexPathsToReload addObject:obj];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.storyView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
            
        } completion:^(BOOL finished){
            if (finished) {
                if (indexPathsToReload.count > 0) {
                    [self.storyView reloadItemsAtIndexPaths:indexPathsToReload];
                    [indexPathsToReload removeAllObjects];
                }
            }
        }];
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
    
    self.showNoContent = [self fetchedStories].count == 0 && self.storiesMode!=DDGStoriesListModeNormal;
}

-(DDGStory*)fetchedStoryAtIndexPath:(NSIndexPath*)indexPath
{
    id fetchedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if(self.storiesMode==DDGStoriesListModeRecents) {
        return ((DDGHistoryItem*)fetchedObject).story;
    }
    return (DDGStory*)fetchedObject;
}


@end
