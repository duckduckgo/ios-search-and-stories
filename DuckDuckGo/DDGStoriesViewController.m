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
#import "SVProgressHUD.h"
#import "AFNetworking.h"
#import "DDGActivityViewController.h"
#import "DDGStoryFetcher.h"
#import "DDGSafariActivity.h"
#import "DDGActivityItemProvider.h"
#import "DDGNoContentViewController.h"
#import <CoreImage/CoreImage.h>
#import "DDGTableView.h"

NSString *const DDGLastViewedStoryKey = @"last_story";
CGFloat const DDGStoriesInterRowSpacing = 10;
CGFloat const DDGStoriesBetweenItemsSpacing = 10;
CGFloat const DDGStoriesMulticolumnWidthThreshold = 500;
CGFloat const DDGStoryImageRatio = 1/0.48f; // 2.083333f;  //1.597f = measured from iPhone screenshot; 1.36f = measured from iPad screenshot
CGFloat const DDGStoryImageRatioMosaic = 1.356f;

NSTimeInterval const DDGMinimumRefreshInterval = 30;

NSInteger const DDGLargeImageViewTag = 1;

@interface DDGStoriesViewController () {
    CIContext *_blurContext;
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
@end



#pragma mark DDGStoriesLayout

static NSString * const DDGStoriesLayoutKind = @"PhotoCell";


@interface DDGStoriesLayout : UICollectionViewLayout
@property (nonatomic, weak) DDGStoriesViewController* storiesController;
@property BOOL mosaicMode;
@property (nonatomic, strong) NSDictionary *layoutInfo;

@end


@implementation DDGStoriesLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup
{
    self.mosaicMode = TRUE;
}

- (void)prepareLayout
{
    NSMutableDictionary *newLayoutInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellLayoutInfo = [NSMutableDictionary dictionary];
    
    NSInteger sectionCount = [self.collectionView numberOfSections];
    
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item = 0; item < itemCount; item++) {
            NSIndexPath* indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            UICollectionViewLayoutAttributes* itemAttributes =
            [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            itemAttributes.frame = [self frameForStoryAtIndexPath:indexPath];
            
            cellLayoutInfo[indexPath] = itemAttributes;
        }
    }
    
    newLayoutInfo[DDGStoriesLayoutKind] = cellLayoutInfo;
    
    self.layoutInfo = newLayoutInfo;
}


CGFloat DDG_rowHeightWithContainerSize(CGSize size) {
    BOOL mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    CGFloat rowHeight;
    if(mosaicMode) { // set to the height of the larger story
        rowHeight = ((size.width - DDGStoriesBetweenItemsSpacing)*2/3) / DDGStoryImageRatio  + DDGTitleBarHeight;
    } else { // set to the height
        rowHeight = size.width / DDGStoryImageRatio + DDGTitleBarHeight;
    }
    return MAX(10.0f, rowHeight); // a little safety
}

- (CGSize)collectionViewContentSize
{
    NSUInteger numStories = [self.collectionView numberOfItemsInSection:0];
    CGSize size = self.collectionView.frame.size;
    self.mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    NSUInteger cellsPerRow = self.mosaicMode ? 3 : 1;
    CGFloat rowHeight = DDG_rowHeightWithContainerSize(size) + DDGStoriesBetweenItemsSpacing;
    NSUInteger numRows = numStories/cellsPerRow;
    if(numStories%cellsPerRow!=0) numRows++;
    size.height = rowHeight * numRows;
    return size;
}



- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray* elementAttributes = [NSMutableArray new];
    CGSize size = self.collectionView.frame.size;
    BOOL mosaicMode = size.width >= DDGStoriesMulticolumnWidthThreshold;
    CGFloat rowHeight = DDG_rowHeightWithContainerSize(size) + DDGStoriesBetweenItemsSpacing;
    
    NSUInteger cellsPerRow = mosaicMode ? 3 : 1;
    NSUInteger rowsBeforeRect = floor(rect.origin.y / rowHeight);
    NSUInteger rowsWithinRect = ceil((rect.origin.y+rect.size.height) / rowHeight) - rowsBeforeRect + 1;
    
    for(NSUInteger row = rowsBeforeRect; row < rowsBeforeRect + rowsWithinRect; row++) {
        for(NSUInteger column = 0 ; column < cellsPerRow; column++) {
            NSUInteger storyIndex = row * cellsPerRow + column;
            if(storyIndex >= [self.collectionView numberOfItemsInSection:0]) break;
            UICollectionViewLayoutAttributes* attributes = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:storyIndex inSection:0]];
            [elementAttributes addObject:attributes];
        }
    }
    return elementAttributes;
}


- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *itemAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    itemAttributes.frame = [self frameForStoryAtIndexPath:indexPath];
    return itemAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return TRUE; // re-layout for all bounds changes
}

- (CGRect)frameForStoryAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.item;
    if(row==NSNotFound) return CGRectZero;
    row = row / (self.mosaicMode ? 3 : 1);
    NSInteger column = indexPath.item % (self.mosaicMode ? 3 : 1);
    CGSize frameSize = self.collectionView.frame.size;
    CGFloat rowHeight = DDG_rowHeightWithContainerSize(frameSize);
    CGFloat rowWidth = frameSize.width;
    BOOL oddRow = (row % 2) == 1;
    
    CGRect storyRect = CGRectMake(0, row * (rowHeight + DDGStoriesBetweenItemsSpacing),
                                  rowWidth, rowHeight);
    if(self.mosaicMode) {
        if(oddRow) {
            if(column==0) { // top left of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
            } else if(column==1) { // bottom left of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
                storyRect.origin.y += rowHeight - storyRect.size.height;
            } else { // if(column==2) // the large right-side story
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)*2/3;
                storyRect.origin.x += rowWidth - storyRect.size.width;
            }
        } else { // even row
            if(column==1) { // top right of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
                storyRect.origin.x += rowWidth - storyRect.size.width;
            } else if(column==2) { // bottom right of three
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)/3;
                storyRect.size.height = (rowHeight - DDGStoriesBetweenItemsSpacing)/2;
                storyRect.origin.y += rowHeight - storyRect.size.height;
                storyRect.origin.x += rowWidth - storyRect.size.width;
            } else { // if(column==0) // the large left-side story
                storyRect.size.width = (rowWidth - DDGStoriesBetweenItemsSpacing)*2/3;
            }
        }
        storyRect.origin.y += DDGStoriesBetweenItemsSpacing;
    } else { // not a mosaic
        // the defaults are good enough
    }
    //NSLog(@"item %lu:  frame: %@", indexPath.item, NSStringFromCGRect(storyRect));

    return storyRect;
}


@end




#pragma mark DDGStoriesViewController


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

- (void)reenableScrollsToTop {
    self.storyView.scrollsToTop = YES;
}

#pragma mark - No Stories

- (void)setShowNoContent:(BOOL)showNoContent {
    [UIView animateWithDuration:0 animations:^{
        self.storyView.hidden = showNoContent;
        self.noContentView.view.hidden = !showNoContent;
    }];
}



#pragma mark - DDGStoryDelegate

-(void)shareStory:(DDGStory*)story fromView:(UIView*)storySource;
{
    NSURL *shareURL = story.URL;
    
    NSString* shareString = [NSString stringWithFormat:@"%@\n\nvia DuckDuckGo for iOS\n", story.title];
    
    NSArray *items = @[shareString, shareURL];
    
    DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:items
                                                                        applicationActivities:@[  ]];
    if ( [avc respondsToSelector:@selector(popoverPresentationController)] ) {
        // iOS8
        avc.popoverPresentationController.sourceView = storySource;
    }

    [self presentViewController:avc animated:YES completion:NULL];
}


-(void)toggleStorySaved:(DDGStory*)story
{
    story.savedValue = !story.savedValue;
    NSManagedObjectContext *context = story.managedObjectContext;
    [context performBlock:^{
        NSError *error = nil;
        if (![context save:&error])
            NSLog(@"error: %@", error);
    }];
    NSString *status = story.savedValue ? NSLocalizedString(@"Added", @"Bookmark Activity Confirmation: Saved") : NSLocalizedString(@"Removed", @"Bookmark Activity Confirmation: Unsaved");
    UIImage *image = story.savedValue ? [[UIImage imageNamed:@"FavoriteSolid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : [[UIImage imageNamed:@"UnfavoriteSolid"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [SVProgressHUD showImage:image status:status];
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
    }];
    NSString *status = NSLocalizedString(@"Removed", @"Recents Activity Confirmation: Removed item from history");
    [SVProgressHUD showSuccessWithStatus:status];
}

-(void)toggleCategoryPressed:(NSString*)categoryName onStory:(DDGStory*)story
{
    if (self.categoryFilter==nil) {
        self.categoryFilter = categoryName;
    } else {
        self.categoryFilter = nil;
    }
    
    NSArray *oldStories = [self fetchedStories];
    [NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
    
    NSDate *feedDate = [[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey];
    self.fetchedResultsController = [self fetchedResultsController:feedDate];
    
    NSArray *newStories = [self fetchedStories];
    [self replaceStories:oldStories withStories:newStories focusOnStory:story];
}



#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    DDGStoriesLayout* storyLayout = [[DDGStoriesLayout alloc] init];
    storyLayout.storiesController = self;
    UICollectionView* storyView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:storyLayout];
    storyView.canCancelContentTouches = TRUE;
    storyView.backgroundColor = [UIColor duckStoriesBackground];
    storyView.dataSource = self;
    storyView.delegate = self;
    storyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [storyView registerClass:DDGStoryCell.class forCellWithReuseIdentifier:DDGStoryCellIdentifier];
    
    if(self.storiesMode==DDGStoriesListModeNormal) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [storyView addSubview:self.refreshControl];
        [self.refreshControl addTarget:self action:@selector(refreshManually) forControlEvents:UIControlEventValueChanged];
    }
    
    [self.view addSubview:storyView];
    self.storyView = storyView;
    
    self.noContentView = [[DDGNoContentViewController alloc] init];
    [self.view addSubview:self.noContentView.view];
    
    self.noContentView.noContentImageview.image = [UIImage imageNamed:@"empty-favorites"];
    self.noContentView.noContentTitle.text = NSLocalizedString(@"No Favorites",
                                                               @"title for the view shown when no favorite searches/urls are found");
    self.noContentView.noContentSubtitle.text = NSLocalizedString(@"Add stories to your favorites, and they will be shown here.",
                                                                  @"details text for the view shown when no favorite stories are found");
    self.noContentView.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.noContentView.view.frame = self.view.bounds;
    
    
    self.fetchedResultsController = [self fetchedResultsController:[[NSUserDefaults standardUserDefaults] objectForKey:DDGStoryFetcherStoriesLastUpdatedKey]];
    
    [self prepareUpcomingCellContent];
    
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
    
    NSNumber *lastStoryID = [[NSUserDefaults standardUserDefaults] objectForKey:DDGLastViewedStoryKey];
    if (nil != lastStoryID) {
        NSArray *stories = [self fetchedStories];
        NSArray *storyIDs = [stories valueForKey:@"id"];
        NSInteger index = [storyIDs indexOfObject:lastStoryID];
        if (index != NSNotFound) {
            [self focusOnStory:[stories objectAtIndex:index] animated:NO];
        }
    }
    
    if (self.storiesMode==DDGStoriesListModeNormal) {
        if ([self shouldRefresh]) {
            [self refreshStoriesTriggeredManually:NO includeSources:YES];
        } else {
            NSLog(@"NOT refreshing stories in normal mode");
        }
    }

    self.showNoContent = [self fetchedStories].count == 0 && self.storiesMode!=DDGStoriesListModeNormal;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // if we animated out, animate back in
    if(_storyView.alpha == 0) {
        _storyView.transform = CGAffineTransformMakeScale(2, 2);
        [UIView animateWithDuration:0.3 animations:^{
            _storyView.alpha = 1;
            _storyView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    //DLog(@"updating %@ with %lu deleted items and %lu new items", storyMode, removedStories.count, addedStories.count);
    [self.storyView reloadSections:[NSIndexSet indexSetWithIndex:0]];

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
            if (story.isImageDownloaded) {
                [self decompressAndDisplayImageForStoryAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
            } else  {
                [self.storyFetcher downloadImageForStory:story];
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self prepareUpcomingCellContent];
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
    [self configureCell:cell atIndexPath:indexPath];
	return cell;
}

#pragma  mark - collection view delegate

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return TRUE;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DDGStory *story = [self fetchedStoryAtIndexPath:indexPath];

    story.readValue = YES;
    
    [[NSUserDefaults standardUserDefaults] setObject:story.id forKey:DDGLastViewedStoryKey];
    
    NSInteger readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    [self.searchHandler loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
    
    [self.historyProvider logStory:story];
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
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
    
    if ([self.enqueuedDecompressionOperations containsObject:cacheKey])
        return;
    
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
                [weakSelf.decompressedImages setObject:decompressed forKey:cacheKey];
            }];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf.enqueuedDecompressionOperations removeObject:cacheKey];
                completionBlock();
            }];
        }];
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
-(NSDate*)lastRefreshAttempt
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* refreshKey = self.lastRefreshDefaultsKey;
    id value = [defaults objectForKey:refreshKey];
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
            NSLog(@"refreshing sources");
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
            weakSelf.fetchedResultsController = [self fetchedResultsController:feedDate];
            
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
        results = [results valueForKey:@"story"];
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
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.storyView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.storyView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
      
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    [self.storyView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    self.showNoContent = [self fetchedStories].count == 0 && self.storiesMode!=DDGStoriesListModeNormal;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //[self.storyView endUpdates];
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

- (void)configureCell:(DDGStoryCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
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
                [weakSelf configureCell:cell atIndexPath:indexPath];
            }];
        }
    }
}


@end
