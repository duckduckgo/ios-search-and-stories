//
//  DDGChooseSourcesViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDGChooseSourcesViewController.h"
#import "DDGStoryFeed.h"
#import "UIImageView+AFNetworking.h"
#import "SVProgressHUD.h"

@interface DDGChooseSourcesViewController ()
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation DDGChooseSourcesViewController

#pragma mark - View controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.tableView.backgroundView = nil;
	self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];
	self.tableView.allowsSelectionDuringEditing = YES;
    self.title = @"Sources";
    
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.rightBarButtonItem = nil;	
    
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
	CGPoint center = self.navigationItem.leftBarButtonItem.customView.center;
	// the actual image is 36px wide but we need 1px horizontal padding on either side
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
	else
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
	self.navigationItem.leftBarButtonItem.customView.center = center;
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

-(void)backButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0)
        return 1;
    else {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section-1];
        return [sectionInfo numberOfObjects];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section==0)
        return @"Suggest a News Source";
    else {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section-1];
        return [sectionInfo name];
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0);
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row == 0)
            return UITableViewCellEditingStyleInsert;
        else
            return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *SourceCellIdentifier = @"SourceCell";
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    
    UITableViewCell *cell = nil;
    
    if(indexPath.section == 0)
	{
        if(indexPath.row == 0)
		{
            cell = [tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
            if(!cell)
			{
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ButtonCellIdentifier];
                cell.textLabel.text = @"Suggest a new source";
				cell.detailTextLabel.text = @"Email us to make a source suggestion.";
                cell.accessoryType = UITableViewCellAccessoryNone;
				cell.textLabel.textColor = [UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0];
            }
        }        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:SourceCellIdentifier];
        if(!cell)
		{
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SourceCellIdentifier];
            
            // keep using the default imageview for layout/spacing purposes, but use our own one for displaying the image
            cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.imageView.alpha = 0;
			cell.textLabel.textColor = [UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, 34, 34)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.tag = 100;
            [cell addSubview:imageView];
        }
        
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

#pragma mark - Mail sender deleagte

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	if(result == MFMailComposeResultSent)
	{
		[SVProgressHUD showSuccessWithStatus:@"Mail sent!"];
	}
	else if (result == MFMailComposeResultFailed)
	{
		[SVProgressHUD showErrorWithStatus:@"Mail send failed!"];
	}
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
	{
		// send an email to make a suggestion for a new source
		if ([MFMailComposeViewController canSendMail])
		{
			MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
			mailVC.mailComposeDelegate = self;
			[mailVC setToRecipients:@[@"ios@duckduckgo.com"]];
			[mailVC setSubject:@"suggestion: story source"];
			[mailVC setMessageBody:@"Please provide a link here so we can investigate the source you would like to see us implement." isHTML:NO];
			[self presentViewController:mailVC animated:YES completion:NULL];
		}
    }
	else
	{
        DDGStoryFeed *feed = [self.fetchedResultsController objectAtIndexPath:[self fetchedResultIndexPathForTableViewIndexPath:indexPath]];
        feed.enabledValue = (!feed.enabledValue);
        
        NSManagedObjectContext *context = feed.managedObjectContext;
        [context performBlock:^{
            NSError *error = nil;
            BOOL success = [context save:&error];
            if (!success)
                NSLog(@"error: %@", error);
        }];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
 
    NSAssert((nil != self.managedObjectContext), @"DDGChooseSourcesViewController requires a managed object context");
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [DDGStoryFeed entityInManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *categoryDescriptor = [[NSSortDescriptor alloc] initWithKey:@"category" ascending:YES];
    NSSortDescriptor *titleDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = @[categoryDescriptor, titleDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:self.managedObjectContext
                                                                                                  sectionNameKeyPath:@"category"
                                                                                                           cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSUInteger tableViewSectionIndex = sectionIndex+1;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:tableViewSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:tableViewSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    NSIndexPath *tableViewIndexPath = [self tableViewIndexPathForFetchedResultsIndexPath:indexPath];
    NSIndexPath *tableViewNewIndexPath = [self tableViewIndexPathForFetchedResultsIndexPath:newIndexPath];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[tableViewNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[tableViewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:tableViewIndexPath] atIndexPath:tableViewIndexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[tableViewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[tableViewNewIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

- (NSIndexPath *)fetchedResultIndexPathForTableViewIndexPath:(NSIndexPath *)indexPath {
    return [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
}

- (NSIndexPath *)tableViewIndexPathForFetchedResultsIndexPath:(NSIndexPath *)indexPath {
    return [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    DDGStoryFeed *feed = [self.fetchedResultsController objectAtIndexPath:[self fetchedResultIndexPathForTableViewIndexPath:indexPath]];

    cell.textLabel.text = feed.title;
    cell.detailTextLabel.text = feed.descriptionString;
    
    UIImage *image = feed.image;    
    cell.imageView.image = image;
    ((UIImageView *)[cell viewWithTag:100]).image = image;
    
    if(feed.enabledValue)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;    
}

@end
