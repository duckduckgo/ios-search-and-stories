//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGViewController.h"
#import "DDGWebViewController.h"
#import "UtilityCHS.h"
#import "SBJson.h"
#import "AFNetworking.h"

@implementation DDGViewController

@synthesize loadedCell;
@synthesize tableView;
@synthesize searchController;
@synthesize entries;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
		
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view];
	searchController.searchHandler = self;
    searchController.state = eViewStateHome;
	[searchController.searchButton setImage:[UIImage imageNamed:@"settings_button.png"] forState:UIControlStateNormal];

    tableView.separatorColor = [UIColor whiteColor];
    
	[self loadEntries];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    searchController.search.text = @""; // reset omnibar text
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	}
	return YES;
}

#pragma mark - Search handler

-(void)loadButton {
    // TODO: implement something here.
}

- (void)loadQuery:(NSString *)query {
    webQuery = query;
    webURL = nil;
    [self performSegueWithIdentifier:@"WebViewSegue" sender:self];
}

-(void)loadURL:(NSString *)url {
    webQuery = nil;
    webURL = url;
    [self performSegueWithIdentifier:@"WebViewSegue" sender:self];
}

// i'll put this here for now because it's closely related to loadQuery:
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"WebViewSegue"])
        if(webQuery)
            [segue.destinationViewController loadQuery:webQuery];
        else if(webURL) {
            [segue.destinationViewController loadURL:webURL];
        }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	UIImageView		*iv;
	
	static NSString *CellIdentifier = @"CurrentTopicCell";
	
	cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = loadedCell;
        self.loadedCell = nil;
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		iv = (UIImageView *)[cell.contentView viewWithTag:100];
		iv.contentMode = UIViewContentModeScaleAspectFill;
		iv.clipsToBounds = YES;
	} else {
        iv = (UIImageView *)[cell.contentView viewWithTag:100];
    }
	
    NSDictionary *entry = [entries objectAtIndex:indexPath.row];

    // use a placeholder image for now, and append the article title to the URL to prevent caching
    NSString *urlString = [NSString stringWithFormat:@"http://lorempixel.com/628/146/?%@",[[entry objectForKey:@"title"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [iv setImageWithURL:[NSURL URLWithString:urlString]];
    
	UILabel *label = (UILabel *)[cell.contentView viewWithTag:200];
	label.text = [entry objectForKey:@"title"];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [entries count];
}

#pragma  mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    webQuery = nil;
    webURL = [[entries objectAtIndex:indexPath.row] objectForKey:@"url"];
    [self performSegueWithIdentifier:@"WebViewSegue" sender:self];
}

#pragma mark - Loading popular stories

- (void)loadEntries
{
    NSURL *url = [NSURL URLWithString:@"http://ddg.watrcoolr.us/?o=json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        self.entries = JSON;
        [tableView reloadData];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"FAILURE: %@",[error userInfo]);
    }];
    [operation start];
}

@end
