//
//  DDGNewsSourcesViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDGNewsSourcesViewController.h"
#import "DDGStoriesProvider.h"
#import "DDGCache.h"
#import "UIImageView+AFNetworking.h"
#import "DDGAddCustomSourceViewController.h"

@implementation DDGNewsSourcesViewController

#pragma mark - View controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Water Cooler";
    self.tableView.allowsSelectionDuringEditing = YES;
    if(self.navigationController.viewControllers.count == 1) {
        // we're the only view controller, so there won't be a back button to get out, so we need a different exit button
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(dismissButtonPressed)];
    }
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return IPAD || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void)dismissButtonPressed {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Adding custom news sources

-(void)addButtonPressed {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Custom News Source" 
                                                    message:@"Enter a keyword to see related news topics" 
                                                   delegate:self 
                                          cancelButtonTitle:@"Cancel" 
                                          otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1+[[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section==0)
        return 1+[DDGStoriesProvider sharedProvider].customSources.count;
    else {
        NSString *category = [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:section-1];
        return [[[[DDGStoriesProvider sharedProvider] sources] objectForKey:category] count];
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
    
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
            if(!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ButtonCellIdentifier];
                cell.textLabel.text = @"Add custom source";
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CustomSourceCellIdentifier];
            if(!cell)
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CustomSourceCellIdentifier];
            
            cell.textLabel.text = [[DDGStoriesProvider sharedProvider].customSources objectAtIndex:indexPath.row-1];
            return cell;
        }
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SourceCellIdentifier];
        if(!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SourceCellIdentifier];
            
            // keep using the default imageview for layout/spacing purposes, but use our own one for displaying the image
            cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.imageView.alpha = 0;
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 5, 34, 34)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.tag = 100;
            [cell addSubview:imageView];
        }
        
        NSString *categoryName = [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:indexPath.section-1];
        NSArray *category = [[[DDGStoriesProvider sharedProvider] sources] objectForKey:categoryName];
        NSDictionary *source = [category objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [source objectForKey:@"title"];
        cell.detailTextLabel.text = [source objectForKey:@"description"];
        
        UIImage *image = [UIImage imageWithData:[DDGCache objectForKey:[source objectForKey:@"link"] inCache:@"sourceImages"]];
        cell.imageView.image = image;
        [(UIImageView *)[cell viewWithTag:100] setImage:image];
        
        if([[DDGCache objectForKey:[source objectForKey:@"id"] inCache:@"enabledSources"] boolValue])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        
        return cell;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        DDGAddCustomSourceViewController *vc = [[DDGAddCustomSourceViewController alloc] initWithDefaults];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        NSString *categoryName = [[DDGCache objectForKey:@"sourceCategories" inCache:@"misc"] objectAtIndex:indexPath.section-1];
        NSArray *category = [[[DDGStoriesProvider sharedProvider] sources] objectForKey:categoryName];
        NSDictionary *source = [category objectAtIndex:indexPath.row];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if(cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            if([[DDGStoriesProvider sharedProvider] enabledSourceIDs].count == 1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoa, there!"
                                                                message:@"You must select at least one news source."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
                [[DDGStoriesProvider sharedProvider] setSourceWithID:[source objectForKey:@"id"] enabled:NO];
            }
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [[DDGStoriesProvider sharedProvider] setSourceWithID:[source objectForKey:@"id"] enabled:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        [[DDGStoriesProvider sharedProvider] deleteCustomSourceAtIndex:indexPath.row-1];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if(editingStyle == UITableViewCellEditingStyleInsert) {
        DDGAddCustomSourceViewController *vc = [[DDGAddCustomSourceViewController alloc] initWithDefaults];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
