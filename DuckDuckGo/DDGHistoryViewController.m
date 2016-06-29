//
//  DDGHistoryViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 10/04/2013.
//
//

#import "DDGAppDelegate.h"
#import "DDGHistoryViewController.h"
#import "DDGHistoryItem.h"
#import "DDGPlusButton.h"
#import "DDGStoryFeed.h"
#import "DDGStory.h"
#import "DDGSettingsViewController.h"
#import "DDGSearchController.h"
#import "DDGHistoryItemCell.h"
#import "DDGUnderViewControllerCell.h"
#import "DDGNoContentViewController.h"
#import "DDGMenuHistoryItemCell.h"


@interface DDGHistoryViewController () {
    BOOL _showingNoResultsSection;
}
@property (nonatomic, weak, readwrite) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) DDGHistoryViewControllerMode mode;
@property (nonatomic, weak) IBOutlet UIImageView *chatBubbleImageView;
@property (nonatomic, strong) DDGNoContentViewController* noContentView;
@property (nonatomic, strong) UIView* separatorView;
@end

@implementation DDGHistoryViewController

-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext mode:(DDGHistoryViewControllerMode)mode;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.searchHandler = searchHandler;
        self.mode = mode;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (nil == self.tableView) {
        UITableView *tableView = nil;
        tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tableView.separatorColor = [UIColor duckTableSeparator];
        tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
        
        tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        tableView.allowsMultipleSelectionDuringEditing = FALSE;
        tableView.sectionFooterHeight = 1;
        tableView.sectionHeaderHeight = 1;
        
        tableView.backgroundColor = [UIColor duckNoContentColor];
        tableView.opaque = NO;
        tableView.rowHeight = 44.0;
        
        self.tableView = tableView;
        [self.view addSubview:self.tableView];
        
        CGRect sepRect = self.view.frame;
        sepRect.origin.x = 0;
        sepRect.origin.y = 0;
        sepRect.size.height = 0.5;
        self.separatorView = [[UIView alloc] initWithFrame:sepRect];
        self.separatorView.backgroundColor = [UIColor duckTableSeparator];
        self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:self.separatorView];
        
        self.noContentView = [[DDGNoContentViewController alloc] init];
        self.noContentView.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.noContentView.view.frame = self.view.bounds;
        self.noContentView.noContentImageview.image = [UIImage imageNamed:@"empty-recents"];
        self.noContentView.contentTitle = NSLocalizedString(@"No Recents",
                                                            @"title for the view shown when no recent searches/urls are found");
        self.noContentView.contentSubtitle = NSLocalizedString(@"Browse stories and search the web, and your recents will be shown here.",
                                                               @"details text for the view shown when no recent searches/urls are found");
        [self.view addSubview:self.noContentView.view];
    }
    
    [self fetchedResultsController];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

-(void)duckGoToTopLevel
{
    if([self tableView:self.tableView numberOfRowsInSection:0]>0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:TRUE];
    }
}


- (NSFetchedResultsController *)fetchedResultsController {
    if (nil == _fetchedResultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGHistoryItem entityName]];
        [request setPredicate:[NSPredicate predicateWithFormat:@"section == %@", DDGHistoryItemSectionNameSearches]];
        NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO];
        [request setSortDescriptors:@[timeSort]];
        
        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:@"section"
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        
        _fetchedResultsController = fetchedResultsController;
    }
    
    return _fetchedResultsController;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if (nil == self.view) {
        self.fetchedResultsController = nil;
    }
}

- (UIImage *)searchControllerBackButtonIconDDG {
    return nil;
}

-(void)plusButtonWasPushed:(DDGMenuHistoryItemCell*)menuCell
{
    if(self.tableView.editing) return; // avoid the case when the plus button was pushed while doing a delete-row swipe
    DDGHistoryItem *historyItem = menuCell.historyItem;
    DDGSearchController *searchController = [self searchControllerDDG];
    if (searchController) {
        DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
        [searchField becomeFirstResponder];
        searchField.text = historyItem.title;
        [searchController searchFieldDidChange:nil];
    } else if ([self.searchHandler respondsToSelector:@selector(beginSearchInputWithString:)]) {
        [self.searchHandler beginSearchInputWithString:historyItem.title];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    [self checkOnNoContent];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


-(void)checkOnNoContent
{
    self.showNoContent = [self.fetchedResultsController fetchedObjects].count <= 0;
}

- (void)setShowNoContent:(BOOL)showNoContent {
    [UIView animateWithDuration:0 animations:^{
        self.tableView.hidden = showNoContent;
        self.noContentView.view.hidden = !showNoContent;
    }];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    DDGStory *story = historyItem.story;
    NSInteger readabilityMode = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    if (nil != story) {
        [self.searchHandler loadStory:story readabilityMode:(readabilityMode == DDGReadabilityModeOnExclusive || readabilityMode == DDGReadabilityModeOnIfAvailable)];
    } else {
        [self.searchHandler loadQueryOrURL:historyItem.title];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle==UITableViewCellEditingStyleDelete) {
        DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
        DDGStory* story = historyItem.story;
        if(story) {
            story.readValue = NO;
        }
        [historyItem.managedObjectContext deleteObject:historyItem];
        [self.managedObjectContext save:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [((DDGAppDelegate*)[[UIApplication sharedApplication] delegate]) updateShortcuts];
        });
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* sections = [self.fetchedResultsController sections];
    return sections.count <= 0 ? 0 : [[self.fetchedResultsController sections][0]  numberOfObjects];
}



- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { return nil; }
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section { return nil; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 1; }
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 0.001; }


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGMenuHistoryItemCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
    if(cell==nil) {
        cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGMenuHistoryItemCell"];
    }
    cell.historyItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.historyDelegate = self;
    cell.isLastItem = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return cell;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
//    NSLog(@"didChangeSection: %i change type: %i", tableSectionIndex, type);
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
                        
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
    [self checkOnNoContent];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
//    NSLog(@"didChangeObject atIndexPath: %@ newIndexPath: %@ change type: %i", tableIndexPath, newTableIndexPath, type);
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            //            [self configureHistoryItemCell:(DDGMenuHistoryItemCell *)[tableView cellForRowAtIndexPath:indexPath]
            //                               atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
    [self checkOnNoContent];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    [self checkOnNoContent];
}

@end
