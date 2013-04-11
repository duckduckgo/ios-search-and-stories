//
//  DDGHistoryViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 10/04/2013.
//
//

#import "DDGHistoryViewController.h"
#import "DDGUnderViewControllerCell.h"
#import "DDGHistoryItem.h"
#import "DDGPlusButton.h"
#import "DDGStoryFeed.h"
#import "DDGStory.h"
#import "DDGSettingsViewController.h"
#import "DDGSearchController.h"

@interface DDGHistoryViewController ()
@property (nonatomic, weak, readwrite) id <DDGSearchHandler> searchHandler;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation DDGHistoryViewController

-(id)initWithSearchHandler:(id <DDGSearchHandler>)searchHandler managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.searchHandler = searchHandler;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (nil == self.tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor colorWithRed:0.161 green:0.173 blue:0.196 alpha:1.000];
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [self.view addSubview:tableView];
        
        self.tableView = tableView;
    }
    
    BOOL showHistory = [[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingRecordHistory];
    
    if (showHistory) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[DDGHistoryItem entityName]];
        NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"timeStamp" ascending:NO];
        NSSortDescriptor *sectionSort = [NSSortDescriptor sortDescriptorWithKey:@"story" ascending:YES];
        [request setSortDescriptors:@[sectionSort, timeSort]];
        
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if (nil == self.view) {
        self.fetchedResultsController = nil;
    }
}

- (UIImage *)searchControllerBackButtonIconDDG {
    return [UIImage imageNamed:@"button_menu_glyph_home"];
}

- (IBAction)plus:(id)sender {
    UIButton *button = nil;
    if ([sender isKindOfClass:[UIButton class]])
        button = (UIButton *)sender;
    
    if (button) {
        CGPoint tappedPoint = [self.tableView convertPoint:button.center fromView:button.superview];
        NSIndexPath *tappedIndex = [self.tableView indexPathForRowAtPoint:tappedPoint];
        DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:tappedIndex];        
        DDGSearchController *searchController = [self searchControllerDDG];
        DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
        
        [searchField becomeFirstResponder];
        searchField.text = historyItem.title;
        [searchController searchFieldDidChange:nil];
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DDGHistoryItem *historyItem = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    [self.historyProvider relogHistoryItem:historyItem];
    DDGStory *story = historyItem.story;
    if (nil != story)
        [self.searchHandler loadStory:story readabilityMode:[[NSUserDefaults standardUserDefaults] boolForKey:DDGSettingStoriesReadView]];
    else
        [self.searchHandler loadQueryOrURL:historyItem.title];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

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
	static NSString *CellIdentifier = @"HistoryCell";
    
	DDGUnderViewControllerCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
	{
        cell = [[DDGUnderViewControllerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.imageView.backgroundColor = self.tableView.backgroundColor;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
	return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 23;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSInteger sections = [self numberOfSectionsInTableView:tableView];
    return (section == (sections-1)) ? 1.0 : 0.0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 23)];
    [headerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_divider.png"]]];
    
    NSArray *sections = [self.fetchedResultsController sections];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width-10, 20)];
    NSString *name = [(id <NSFetchedResultsSectionInfo>)[sections objectAtIndex:section] name];
    
    if ([name isEqualToString:@"searches"]) {
        title.text = NSLocalizedString(@"Recent Searches", @"Table section header title");
    } else if ([name isEqualToString:@"stories"]) {
        title.text = NSLocalizedString(@"Recent Stories", @"Table section header title");
    } else {
        title.text = name;
    }
    
    title.textColor = [UIColor whiteColor];
    title.opaque = NO;
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:13.0];
    [headerView addSubview:title];
    
    return headerView;
}

-(UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 1)];
    [footerView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"end_of_list_highlight.png"]]];
    
    return footerView;
}

#pragma mark - NSFetchedResultsControllerDelegate

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
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    DDGUnderViewControllerCell *underCell = (DDGUnderViewControllerCell *)cell;
    
    underCell.active = NO;
    
	underCell.imageView.image = nil;
    underCell.imageView.highlightedImage = nil;
    underCell.overhangWidth = 6.0;
    
	UILabel *lbl = cell.textLabel;

    underCell.cellMode = DDGUnderViewControllerCellModeRecent;

    // we have history and it is enabled
    DDGHistoryItem *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    DDGStory *story = item.story;

    if (nil != story) {
        cell.imageView.image = story.feed.image;
        cell.accessoryView = nil;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"search_icon"];
        cell.accessoryView = [DDGPlusButton plusButton];
    }
    lbl.text = item.title;

}

@end
