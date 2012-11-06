//
//  DDGChooseSourcesViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDGChooseSourcesViewController.h"
#import "DDGNewsProvider.h"
#import "DDGCache.h"
#import "UIImageView+AFNetworking.h"
#import "SVProgressHUD.h"

@implementation DDGChooseSourcesViewController

#pragma mark - View controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.tableView.backgroundView = nil;
	self.tableView.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];
	self.tableView.allowsSelectionDuringEditing = YES;
    self.title = @"Water Cooler";
    
    
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 38, 31); // the actual image is 36px wide but we need 1px horizontal padding on either side
    
    // we need to offset the triforce image by 1px down to compensate for the shadow in the image
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return IPAD || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
    return 1+[[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0)
        return 1+[DDGNewsProvider sharedProvider].customSources.count;
    else {
        NSString *category = [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:section-1];
        return [[[[DDGNewsProvider sharedProvider] sources] objectForKey:category] count];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section==0)
        return @"Custom sources";
    else
        return [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:section-1];
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
    static NSString *CustomSourceCellIdentifier = @"CustomSourceCell";
    
    if(indexPath.section == 0)
	{
        if(indexPath.row == 0)
		{
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
            if(!cell)
			{
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ButtonCellIdentifier];
                cell.textLabel.text = @"Suggest a new source";
				cell.detailTextLabel.text = @"Email us to make a source suggestion.";
                cell.accessoryType = UITableViewCellAccessoryNone;
				cell.textLabel.textColor = [UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0];
            }
            return cell;
        }
		else
		{
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CustomSourceCellIdentifier];
            if(!cell)
			{
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CustomSourceCellIdentifier];
				cell.textLabel.textColor = [UIColor colorWithRed:0.29 green:0.30 blue:0.32 alpha:1.0];
            }
            cell.textLabel.text = [[DDGNewsProvider sharedProvider].customSources objectAtIndex:indexPath.row-1];
            return cell;
        }
    }
	else
	{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SourceCellIdentifier];
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
        
        NSString *categoryName = [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:indexPath.section-1];
        NSArray *category = [[[DDGNewsProvider sharedProvider] sources] objectForKey:categoryName];
        NSDictionary *source = [category objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [source objectForKey:@"title"];
        cell.detailTextLabel.text = [source objectForKey:@"description"];
        
        if([source objectForKey:@"link"] && [source objectForKey:@"link"] != [NSNull null]) {
            UIImage *image = [DDGCache objectForKey:[source objectForKey:@"link"] inCache:@"sourceImages"];
            cell.imageView.image = image;
            [(UIImageView *)[cell viewWithTag:100] setImage:image];
        } else {
            cell.imageView.image = nil;
            [(UIImageView *)[cell viewWithTag:100] setImage:nil];

        }
        
        if([[DDGCache objectForKey:[source objectForKey:@"id"] inCache:@"enabledSources"] boolValue])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        return cell;
    }
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
	[self dismissModalViewControllerAnimated:YES];
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
			[mailVC setSubject:@"suggestion: water cooler source"];
			[mailVC setMessageBody:@"Please provide a link here so we can investigate the source you would like to see us implement." isHTML:NO];
			[self presentModalViewController:mailVC animated:YES];
		}
    }
	else
	{
        NSString *categoryName = [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:indexPath.section-1];
        NSArray *category = [[[DDGNewsProvider sharedProvider] sources] objectForKey:categoryName];
        NSDictionary *source = [category objectAtIndex:indexPath.row];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if(cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            if([[DDGNewsProvider sharedProvider] enabledSourceIDs].count == 1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoa, there!"
                                                                message:@"You must select at least one news source."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[DDGNewsProvider sharedProvider] setSourceWithID:[source objectForKey:@"id"] enabled:NO];
            }
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [[DDGNewsProvider sharedProvider] setSourceWithID:[source objectForKey:@"id"] enabled:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
