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
#import "DDGUnderViewController.h"
#import "ECSlidingViewController.h"
#import "DDGPlusButton.h"
#import "DDGHistoryItemCell.h"

@interface DDGBookmarksViewController ()
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@property (nonatomic, strong) UIImage *searchIcon;
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

    NSParameterAssert(nil != self.searchController);
    
    self.tableView.frame = self.view.bounds;
    [self.view addSubview:self.tableView];    
    
    self.searchIcon = [UIImage imageNamed:@"search_icon"];
            
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"button_menu-default"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"button_menu-onclick"] forState:UIControlStateHighlighted];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);

    [button addTarget:self action:@selector(leftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    self.doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Menu button label: Done")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(editAction:)];

    self.editBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"Menu button label: Edit")
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(editAction:)];    
	// force 1st time through for iOS < 6.0
	[self viewWillLayoutSubviews];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    UIGestureRecognizer *panGesture = [self.slideOverMenuController panGesture]; //[self.slidingViewController panGesture];
    for (UIGestureRecognizer *gr in self.tableView.gestureRecognizers) {
        if ([gr isKindOfClass:[UISwipeGestureRecognizer class]])
            [panGesture requireGestureRecognizerToFail:gr];
    }
    
    self.navigationItem.rightBarButtonItem = ([DDGBookmarksProvider sharedProvider].bookmarks.count)  ? self.editBarButtonItem : nil;
    
    if ([DDGBookmarksProvider sharedProvider].bookmarks.count == 0)
        [self showNoBookmarksView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tableView setEditing:NO animated:animated];
}

#pragma mark - Rotation

- (void)viewWillLayoutSubviews
{
	CGPoint cl = self.navigationItem.leftBarButtonItem.customView.center;
//	CGPoint cr = self.navigationItem.rightBarButtonItem.customView.center;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
	{
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
//		self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(0, 0, 40, 23);
	}
	else
	{
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
//		self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(0, 0, 58, 33);
	}
	self.navigationItem.leftBarButtonItem.customView.center = cl;
//	self.navigationItem.rightBarButtonItem.customView.center = cr;
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

-(void)leftButtonPressed {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

#pragma mark - No Bookmarks

- (void)showNoBookmarksView {
    
    [UIView animateWithDuration:0 animations:^{
        [self.tableView removeFromSuperview];
        self.noBookmarksView.frame = self.view.bounds;
        [self.view addSubview:self.noBookmarksView];
    }];
}

- (void)hideNoBookmarksView {
    if (nil == self.tableView.superview) {
        [UIView animateWithDuration:0 animations:^{
            [self.noBookmarksView removeFromSuperview];
            self.tableView.frame = self.view.bounds;
            [self.view addSubview:self.tableView];
        }];
    }
}

/*
 
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
 
 */

- (IBAction)delete:(id)sender {
    NSSet *indexPaths = [self.deletingIndexPaths copy];
    [self cancelDeletingIndexPathsAnimated:YES];
    
    for (NSIndexPath *indexPath in indexPaths) {
        [[DDGBookmarksProvider sharedProvider] deleteBookmarkAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if ([DDGBookmarksProvider sharedProvider].bookmarks.count == 0)
            [self performSelector:@selector(showNoBookmarksView) withObject:nil afterDelay:0.2];
    }
}

- (IBAction)plus:(id)sender {
    UIButton *button = nil;
    if ([sender isKindOfClass:[UIButton class]])
        button = (UIButton *)sender;
    
    if (button) {
        CGPoint tappedPoint = [self.tableView convertPoint:button.center fromView:button.superview];
        NSIndexPath *tappedIndex = [self.tableView indexPathForRowAtPoint:tappedPoint];        
        NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:tappedIndex.row];
        DDGAddressBarTextField *searchField = self.searchController.searchBar.searchField;
        
        [searchField becomeFirstResponder];
        searchField.text = [bookmark objectForKey:@"title"];
        [self.searchController searchFieldDidChange:nil];
    }
}

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
    static NSString *CellIdentifier = @"Cell";
    DDGHistoryItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
	{
        cell = [[DDGHistoryItemCell alloc] initWithCellMode:DDGHistoryItemCellModeNormal reuseIdentifier:CellIdentifier];
        cell.fixedSizeImageView.size = CGSizeMake(16.0, 16.0);
        cell.overhangWidth = 6.0;
        cell.accessoryView = [DDGPlusButton plusButton];
    }
    
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    cell.textLabel.text = [bookmark objectForKey:@"title"];
    cell.fixedSizeImageView.image = self.searchIcon;
//    cell.detailTextLabel.text = [bookmark objectForKey:@"url"];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    [self.searchHandler loadQueryOrURL:[bookmark objectForKey:@"url"]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
