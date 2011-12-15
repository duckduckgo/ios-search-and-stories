//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DDGViewController.h"
#import "DDGWebViewController.h"
#import "UtilityCHS.h"
#import "JSON.h"

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
	// Do any additional setup after loading the view, typically from a nib.
	// Do any additional setup after loading the view, typically from a nib.
	
	self.searchController = [[[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view] autorelease];
	searchController.searchHandler = self;
    searchController.state = eViewStateHome;
	[searchController.searchButton setImage:[UIImage imageNamed:@"gear40x37.png"] forState:UIControlStateNormal];
	
	[self loadEntries];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
	self.searchController = nil;
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

#pragma - search handler action happening

- (void)actionTaken:(NSDictionary*)action
{
	if ([[action objectForKey:ksDDGSearchControllerAction] isEqualToString:ksDDGSearchControllerActionWeb] && [action objectForKey:ksDDGSearchControllerSearchTerm])
	{
        DDGWebViewController *wvc = [self.storyboard instantiateViewControllerWithIdentifier:@"WebView"];
        
        NSString *urlString = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&ko=-1", [action objectForKey:ksDDGSearchControllerSearchTerm]];
        
        urlString = [UtilityCHS fixupURL:urlString];
        
        wvc.params = [NSDictionary dictionaryWithObjectsAndKeys:
					  [action objectForKey:ksDDGSearchControllerSearchTerm], ksDDGSearchControllerSearchTerm,
					  [NSURL URLWithString:urlString], ksDDGSearchControllerSearchURL, 
					  nil];
        
        [self.navigationController pushViewController:wvc animated:YES];
	}
}

#pragma  mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	static NSString *CellIdentifier = @"CurrentTopicCell";
	
	cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
        [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = loadedCell;
        self.loadedCell = nil;
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	// Configure the cell...
	UIImageView *iv = (UIImageView *)[cell.contentView viewWithTag:100];
	
	iv.image = [UIImage imageNamed:[NSString stringWithFormat:@"Temporary/mm%d.png", (indexPath.row % 5) + 1]];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 15; //[entries count];
}

#pragma  mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma - load up entries for  home screen

- (void)loadEntries
{
//    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Temporary/feedHomeScreen" ofType:@"json"];
//	NSError *error = nil;
//	NSString *json = [NSString stringWithContentsOfFile:bundlePath encoding:NSUTF8StringEncoding error:&error];
//	self.entries = [json JSONValue];
}

@end
