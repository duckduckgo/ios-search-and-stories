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

#import "DDGCache.h"

@implementation DDGBookmarksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Saved";

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"triforce_button.png"] forState:UIControlStateNormal];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);

    [button addTarget:self action:@selector(leftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[button setImage:[UIImage imageNamed:@"edit_button.png"] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:@"done_button.png"] forState:UIControlStateSelected];
	[button addTarget:self action:@selector(editAction:) forControlEvents:UIControlEventTouchUpInside];
	button.hidden = ![DDGBookmarksProvider sharedProvider].bookmarks.count;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	// force 1st time through for iOS < 6.0
	[self viewWillLayoutSubviews];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Rotation

- (void)viewWillLayoutSubviews
{
	CGPoint cl = self.navigationItem.leftBarButtonItem.customView.center;
	CGPoint cr = self.navigationItem.rightBarButtonItem.customView.center;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
	{
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
		self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(0, 0, 40, 23);
	}
	else
	{
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
		self.navigationItem.rightBarButtonItem.customView.frame = CGRectMake(0, 0, 58, 33);
	}
	self.navigationItem.leftBarButtonItem.customView.center = cl;
	self.navigationItem.rightBarButtonItem.customView.center = cr;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)editAction:(UIButton*)button
{
	BOOL edit = !button.selected;
	button.selected = edit;
	[self.tableView setEditing:edit animated:YES];
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
		cell.imageView.image = [UIImage imageNamed:@"spacer32x32.png"];
		UIImageView *iv  = [[UIImageView alloc] initWithFrame:CGRectMake(11, 11, 32, 32)];
		[cell.contentView addSubview:iv];
		iv.tag = 100;
		iv.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    NSDictionary *bookmark = [[DDGBookmarksProvider sharedProvider].bookmarks objectAtIndex:indexPath.row];
    cell.textLabel.text = [bookmark objectForKey:@"title"];
    cell.detailTextLabel.text = [[bookmark objectForKey:@"url"] absoluteString];

	NSString *feed = [bookmark objectForKey:@"feed"];
	if ([feed isEqualToString:@"search_icon.png"])
	{
		((UIImageView *)[cell viewWithTag:100]).image = [UIImage imageNamed:feed];
	}
	else if (feed)
	{
		((UIImageView *)[cell viewWithTag:100]).image = [DDGCache objectForKey:feed inCache:@"sourceImages"];
	}
	else
		((UIImageView *)[cell viewWithTag:100]).image = nil;

    return cell;
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
    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadQueryOrURL:[[bookmark objectForKey:@"url"] absoluteString]];
}

@end
