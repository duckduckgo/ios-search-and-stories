//
//  DDGBookmarksViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/29/12.
//
//

#import "DDGBookmarksViewController.h"
#import "DDGBookmarksProvider.h"
#import "DDGSearchController.h"
#import "DDGPlusButton.h"
#import "DDGMenuHistoryItemCell.h"
#import "DDGNoContentViewController.h"

@interface DDGBookmarksViewController ()
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *separatorView;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic, strong) UIImage *searchIcon;
@property (nonatomic, strong) DDGNoContentViewController* noContentView;

@end

@implementation DDGBookmarksViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Bookmarks", @"View controller title: Bookmarks");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor duckNoContentColor]];
    self.separatorView.backgroundColor = [UIColor duckTableSeparator];
    
    NSParameterAssert(nil != self.searchController);
    
    self.tableView.rowHeight = 44.0f;
    self.tableView.separatorColor = [UIColor duckTableSeparator];
    self.tableView.backgroundColor = [UIColor duckNoContentColor];
    self.tableView.sectionFooterHeight = 0;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 0);
    self.tableView.sectionFooterHeight = 1;
    self.tableView.sectionHeaderHeight = 1;
    
    self.searchIcon = [UIImage imageNamed:@"search_icon"];
    
    self.doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Menu button label: Done")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(editAction:)];

    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Menu button label: Edit")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(editAction:)];
    
    self.noContentView = [[DDGNoContentViewController alloc] init];
    self.noContentView.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.noContentView.view.frame = self.view.bounds;
    self.noContentView.noContentImageview.image = [UIImage imageNamed:@"empty-favorites"];
    self.noContentView.contentTitle = NSLocalizedString(@"No Favorites",
                                                        @"title for the view shown when no favorite searches/urls are found");
    self.noContentView.contentSubtitle = NSLocalizedString(@"Add searches to your favorites, and they will be shown here.",
                                                           @"details text for the view shown when no favorite searches/urls are found");
    [self.view addSubview:self.noContentView.view];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.navigationItem.rightBarButtonItem = ([DDGBookmarksProvider sharedProvider].bookmarks.count)  ? self.editBarButtonItem : nil;
    
    self.showNoContent = [DDGBookmarksProvider sharedProvider].bookmarks.count == 0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tableView setEditing:NO animated:animated];
}


- (void)setShowNoContent:(BOOL)showNoContent {
    
    [UIView animateWithDuration:0 animations:^{
        self.tableView.hidden = showNoContent;
        self.noContentView.view.hidden = !showNoContent;
    }];
}


-(void)plusButtonWasPushed:(DDGMenuHistoryItemCell*)menuCell
{
    DDGSearchController *searchController = [self searchControllerDDG];
    if (searchController) {
        DDGAddressBarTextField *searchField = searchController.searchBar.searchField;
        [searchField becomeFirstResponder];
        if(menuCell.historyItem) {
            searchField.text = menuCell.historyItem.title;
        } else if(menuCell.bookmarkItem) {
            searchField.text = menuCell.bookmarkItem[@"title"];
        }
        [searchController searchFieldDidChange:nil];
    } else if ([self.searchHandler respondsToSelector:@selector(beginSearchInputWithString:)]) {
        [self.searchHandler beginSearchInputWithString:menuCell.historyItem.title];
    }
}



#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)editAction:(UIBarButtonItem *)buttonItem
{
	BOOL edit = (buttonItem == self.editBarButtonItem);
	[self.tableView setEditing:edit animated:YES];
    [self.navigationItem setRightBarButtonItem:(edit ? self.doneBarButtonItem : self.editBarButtonItem) animated:NO];
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


//- (IBAction)delete:(id)sender {
//    NSSet *indexPaths = [self.deletingIndexPaths copy];
//    [self cancelDeletingIndexPathsAnimated:YES];
//    
//    for (NSIndexPath *indexPath in indexPaths) {
//        [[DDGBookmarksProvider sharedProvider] deleteBookmarkAtIndex:indexPath.row];
//        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        
//        if ([DDGBookmarksProvider sharedProvider].bookmarks.count == 0)
//            [self performSelector:@selector(showNoBookmarksView) withObject:nil afterDelay:0.2];
//    }
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger count = [DDGBookmarksProvider sharedProvider].bookmarks.count;
	((UIButton*)self.navigationItem.rightBarButtonItem.customView).hidden = !count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *bookmark = [[[DDGBookmarksProvider sharedProvider] bookmarks] objectAtIndex:indexPath.row];
    DDGMenuHistoryItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DDGMenuHistoryItemCell"];
    if(cell==nil) {
        cell = [[DDGMenuHistoryItemCell alloc] initWithReuseIdentifier:@"DDGMenuHistoryItemCell"];
    }
    cell.bookmarkItem = bookmark;
    cell.historyDelegate = self;
    cell.isLastItem = indexPath.row + 1 >= [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section { return nil; }
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section { return nil; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 1; }
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 0.001; }


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    [self.searchHandler loadQueryOrURL:[bookmark objectForKey:@"url"]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TRUE;
}


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        [[DDGBookmarksProvider sharedProvider] deleteBookmarkAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        self.showNoContent = [DDGBookmarksProvider sharedProvider].bookmarks.count == 0;
    }
}

@end
