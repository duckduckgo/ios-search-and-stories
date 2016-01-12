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
#import "DDGSettingsViewController.h"
#import "DDGSourceSettingCellTableViewCell.h"
#import "DDGStoryFetcher.h"

@interface DDGChooseSourcesViewController ()
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation DDGChooseSourcesViewController


#pragma mark - View controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Sources", "View Controller Title: Sources");
    
    [DDGSettingsViewController configureTable:self.tableView];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.rowHeight = 50;
    
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
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
    if(section==0) {
        return 2;
    } else {
        section--;
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return [sectionInfo numberOfObjects];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section==0) {
        return NSLocalizedString(@"Options", @"Header for the Options section in the Source selection view");
    } else {
        section--;
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return [sectionInfo name];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section-1;
    return section == 0;
}

-(UITableViewCell*)buttonCellWithTitle:(NSString*)title forTableView:(UITableView*)tableView
{
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    UITableViewCell* buttonCell = [tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
    if(!buttonCell) {
        buttonCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ButtonCellIdentifier];
    }
    buttonCell.textLabel.text = title;
    //buttonCell.textLabel.textAlignment = NSTextAlignmentCenter;
    buttonCell.textLabel.font = [UIFont duckFontWithSize:buttonCell.textLabel.font.pointSize];
    buttonCell.accessoryType = UITableViewCellAccessoryNone;
    buttonCell.textLabel.textColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];
    return buttonCell;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *SourceCellIdentifier = @"DDGSourceCell";
    
    if(indexPath.section==0) {
        switch(indexPath.row) {
            case 0:
                return [self buttonCellWithTitle:NSLocalizedString(@"Reset to Default", @"Table button/row to reset the list of sources to the default values")
                                    forTableView:tableView];
            case 1:
            default:
                return [self buttonCellWithTitle:NSLocalizedString(@"Suggest a Source", @"Table button/row to suggest a new source")
                                    forTableView:tableView];
                
        }
    } else {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
        
        DDGSourceSettingCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SourceCellIdentifier];
        if(!cell) {
            cell = [[DDGSourceSettingCellTableViewCell alloc] initWithReuseIdentifier:SourceCellIdentifier];
        }
        [DDGSettingsViewController configureSettingsCell:cell];
        cell.feed = [self.fetchedResultsController objectAtIndexPath:indexPath];
        //[self configureCell:cell atIndexPath:indexPath];
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [DDGSettingsViewController createSectionHeaderView:[self tableView:tableView titleForHeaderInSection:section]];
}


#pragma mark - Mail sender deleagte

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section==0) {
        [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
        if(indexPath.row==0) {
            [DDGStoryFetcher resetSourceFeedsToDefaultInContext:self.fetchedResultsController.managedObjectContext];
        } else {
            // send an email to make a suggestion for a new source
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
                mailVC.mailComposeDelegate = self;
                [mailVC setToRecipients:@[@"stories@duckduckgo.com"]];
                [mailVC setSubject:@"Suggestion: Story Source"];
                [mailVC setMessageBody:@"Please let us know the source you would like us to investigate adding and why. Note that we will only consider sources that have some sort of aggregated feed like \"most up-voted\" or \"most shared\". Also, if you have any feedback about the Stories feature, we would love to hear it!" isHTML:NO];
                [self presentViewController:mailVC animated:YES completion:NULL];
            }
        }
    } else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section-1];
        DDGStoryFeed *feed = [self.fetchedResultsController objectAtIndexPath:indexPath];
        feed.feedState = (feed.feedState == DDGStoryFeedStateEnabled) ? DDGStoryFeedStateDisabled : DDGStoryFeedStateEnabled;
        NSManagedObjectContext *context = feed.managedObjectContext;
        [context performBlock:^{
            NSError *error = nil;
            BOOL success = [context save:&error];
            if (!success) {
                NSLog(@"error: %@", error);
            }
        }];
        //[self.tableView reloadRowsAtIndexPaths:@[originalIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
 
    NSAssert((nil != self.managedObjectContext), @"DDGChooseSourcesViewController requires a managed object context");
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[DDGStoryFeed entityName]];
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

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    NSUInteger tableViewSectionIndex = sectionIndex+1;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:tableViewSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:tableViewSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
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
    //indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1];
    //newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section+1];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section+1]]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1]]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1]]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section+1]]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section+1]]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    DDGStoryFeed *feed = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.imageView.alpha = 0;
    UIImageView* imageView = (UIImageView *)[cell viewWithTag:100];
    imageView.image = feed.image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;//ScaleAspectFill;
    imageView.frame = CGRectMake(15, 5, 40, 40);
    imageView.autoresizingMask = UIViewAutoresizingNone;
    
    cell.textLabel.text = feed.title;
    cell.detailTextLabel.text = feed.descriptionString;
    cell.imageView.image = feed.image;
    
    CGRect textRect = cell.textLabel.frame;
    textRect.origin.x = 10;
    cell.textLabel.frame = textRect;
    cell.textLabel.backgroundColor = [UIColor redColor];
    
    //    cell.textLabel.textColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];
    //    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    
    if(feed.feedState == DDGStoryFeedStateEnabled) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
