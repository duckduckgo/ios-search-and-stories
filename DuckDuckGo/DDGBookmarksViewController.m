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

@interface DDGBookmarksViewController ()
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;
@end

@implementation DDGBookmarksViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"Bookmarks", @"View controller title: Bookmarks");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
    
    self.navigationItem.rightBarButtonItem = ([DDGBookmarksProvider sharedProvider].bookmarks.count)  ? self.editBarButtonItem : nil;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 54.0;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.imageView.image = [UIImage imageNamed:@"spacer23x23.png"];
        UIImageView *iv = (UIImageView *)[cell viewWithTag:100];
        if (nil == iv)
            iv  = [[UIImageView alloc] initWithFrame:CGRectMake(11, 16, cell.imageView.image.size.width, cell.imageView.image.size.height)];
		[cell.contentView addSubview:iv];
		iv.tag = 100;
		iv.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    cell.textLabel.text = [bookmark objectForKey:@"title"];
    cell.detailTextLabel.text = [bookmark objectForKey:@"url"];

    ((UIImageView *)[cell viewWithTag:100]).image = [UIImage imageNamed:@"search_icon"];    

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[DDGBookmarksProvider sharedProvider] deleteBookmarkAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [[DDGBookmarksProvider sharedProvider] moveBookmarkAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:[bookmark objectForKey:@"url"]];
}

@end
