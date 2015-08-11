//
//  DDGHistoryViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 10/04/2013.
//
//

#import "DDGHistoryViewController.h"
#import "DDGHistoryItem.h"
#import "DDGPlusButton.h"
#import "DDGStoryFeed.h"
#import "DDGStory.h"
#import "DDGSettingsViewController.h"
#import "DDGSearchController.h"
#import "DDGHistoryItemCell.h"
#import "DDGUnderViewControllerCell.h"

#import "DDGMenuHistoryItemCell.h"


@interface DDGHistoryViewController () <UIGestureRecognizerDelegate> {
    BOOL _showingNoResultsSection;
}
@property (nonatomic, weak, readwrite) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) DDGHistoryViewControllerMode mode;
@property (nonatomic, weak) IBOutlet UIImageView *chatBubbleImageView;
@end

@implementation DDGHistoryViewController

-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext mode:(DDGHistoryViewControllerMode)mode;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.searchHandler = searchHandler;
        self.showsHistory = YES;
        self.mode = mode;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (nil == self.tableView) {
        UITableView *tableView = nil;
        tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.separatorColor = [UIColor duckTableSeparator];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        tableView.allowsMultipleSelectionDuringEditing = FALSE;
        
        tableView.backgroundColor = [UIColor clearColor];
        tableView.opaque = NO;
        tableView.rowHeight = 44.0;
        //[tableView registerNib:[UINib nibWithNibName:@"DDGMenuHistoryItemCell" bundle:nil] forCellReuseIdentifier:@"DDGMenuHistoryItemCell"];
        
        self.view = tableView;
        self.tableView = tableView;
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

- (NSFetchedResultsController *)fetchedResultsController {
    if (nil == _fetchedResultsController && self.showsHistory) {
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
        if (![fetchedResultsController performFetch:&error])
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        self.fetchedResultsController = fetchedResultsController;
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
    return [[UIImage imageNamed:@"Home"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(void)plusButtonWasPushed:(DDGHistoryItem*)historyItem
{
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
    
    if ([self shouldShowNoHistoryView]) {
        [self showNoResultsView];
    } else {
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;
    }
    
    if ([self shouldShowNoHistorySection]) {
        [self showNoResultsSection];
    }
}

- (BOOL)shouldShowNoHistorySection {
    return ([[self.fetchedResultsController fetchedObjects] count] == 0)
    && FALSE // nil != self.additionalSectionsDelegate
    && self.showsHistory;
}

- (void)showNoResultsSection {
    if (!_showingNoResultsSection) {
        _showingNoResultsSection = YES;
        [self.tableView beginUpdates];
        
        NSInteger sections = [[self.fetchedResultsController sections] count];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(sections)];
        
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];
    }
}

- (void)hideNoResultsSection {
    if (_showingNoResultsSection) {
        _showingNoResultsSection = NO;
        [self.tableView beginUpdates];
        
        NSInteger sections = [[self.fetchedResultsController sections] count];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:(sections)];
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        
        [self.tableView endUpdates];        
    }
}

- (BOOL)shouldShowNoHistoryView {
    return ([[self.fetchedResultsController fetchedObjects] count] == 0)
    && self.showsHistory;
}

- (void)showNoResultsView {
    // show no results view
    if (nil == self.noResultsView) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory])
            [[NSBundle mainBundle] loadNibNamed:@"DDGHistoryNoResultsView" owner:self options:nil];
        else
            [[NSBundle mainBundle] loadNibNamed:@"DDGHistoryNoResultsDisabledView" owner:self options:nil];
    }
    [self.noResultsView setTintColor:[UIColor whiteColor]];
    [self.chatBubbleImageView setImage:[[UIImage imageNamed:@"Chat"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.noResultsView setFrame:[self.view bounds]];
    [self.view addSubview:self.noResultsView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIGestureRecognizer *panGesture = [self.slideOverMenuController panGesture];
    for (UIGestureRecognizer *gr in self.tableView.gestureRecognizers) {
        if ([gr isKindOfClass:[UISwipeGestureRecognizer class]])
            [panGesture requireGestureRecognizerToFail:gr];
    }
}

- (void)setShowsHistory:(BOOL)showsHistory {
    if (showsHistory == _showsHistory)
        return;
    
    _showsHistory = showsHistory;
    
    if (!showsHistory)
        self.fetchedResultsController = nil;
    
    [self.tableView reloadData];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    return (nil != indexPath);
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
        [historyItem.managedObjectContext deleteObject:historyItem];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* sections = [self.fetchedResultsController sections];
    return sections.count <= 0 ? 0 : [[self.fetchedResultsController sections][0]  numberOfObjects];
}



- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(section==0) return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 2)];
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DDGMenuHistoryItemCell* cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
    if(cell==nil) {
        cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGMenuHistoryItemCell"];
    }
    cell.historyItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.historyDelegate = self;
    cell.separatorView.hidden = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return cell;
}

//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
//    if (section < additionalSections) {
//        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)])
//            return [self.additionalSectionsDelegate tableView:tableView heightForFooterInSection:section];
//    }
//    
//    return 0.0;
//}
//
//-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    NSInteger additionalSections = [self.additionalSectionsDelegate numberOfAdditionalSections];
//    if (section < additionalSections) {
//        if ([self.additionalSectionsDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)])
//            return [self.additionalSectionsDelegate tableView:tableView viewForFooterInSection:section];
//        return nil;
//    }
//        
//    return nil;
//}

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
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    
    if ([self shouldShowNoHistoryView]) {
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;
    } else if ([self shouldShowNoHistorySection]) {
        [self showNoResultsSection];
    } else {
        [self hideNoResultsSection];
        [self.noResultsView removeFromSuperview];
        self.noResultsView = nil;        
    }
}

//- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
//{
//    DDGHistoryItemCell *underCell = (DDGHistoryItemCell *)cell;
//    
//    underCell.imageView.image = nil;
//    underCell.imageView.highlightedImage = nil;
//    
//    UILabel *lbl = cell.textLabel;
//
//    // we have history and it is enabled
//    DDGHistoryItem *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    DDGStory *story = item.story;
//    
//    if (nil != story) {
//        underCell.fixedSizeImageView.image = story.feed.image;
//        cell.accessoryView = nil;
//    } else {
//        underCell.fixedSizeImageView.image = [UIImage imageNamed:@"search_icon"];
//        cell.accessoryView = [DDGPlusButton plusButton];
//    }
//    lbl.text = item.title;
//}

@end
