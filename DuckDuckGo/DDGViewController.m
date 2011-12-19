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
#import "JSON.h"
#import "NSString+SBJSON.h"

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
	
	dataHelper = [[DataHelper alloc] initWithDelegate:self];
	
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
	[dataHelper release];
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
	NSDictionary *entry = [entries objectAtIndex:indexPath.row];
	
	// Configure the cell...
	UIImageView *iv = (UIImageView *)[cell.contentView viewWithTag:100];
	
	id mc = [entry objectForKey:@"media:content"];
	
	NSString *iurl = nil;
	
	if ([mc isKindOfClass:[NSArray class]] && [mc count])
	{
		iurl = [[mc objectAtIndex:0] objectForKey:@"url"];
		iv.image = [self loadImage:iurl];
	}
	else if ([mc isKindOfClass:[NSDictionary class]])
	{
		iurl = [mc objectForKey:@"url"];
		iv.image = [self loadImage:iurl];
	}
	else
		iv.image = [UIImage imageNamed:@"duckPlaceholder314x73.png"];

	UILabel *lbl = (UILabel *)[cell.contentView viewWithTag:200];
	
	lbl.text = [entry objectForKey:@"title"];
	
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
}

#pragma - load up entries for  home screen

#define anURL 

- (UIImage*)loadImage:(NSString*)url
{
	NSData *img = [dataHelper retrieve:url
								 store:kCacheStoreIndexImages
								  name:[NSString stringWithFormat:@"%08x", [url hash]]
							returnData:YES
							identifier:2000
							bufferSize:8192];
	if (img)
		return [UIImage imageWithData:img];
	return nil;
}

- (void)loadEntries
{
	[dataHelper retrieve:@"http://pipes.yahoo.com/pipes/pipe.run?_id=96061e78ec401aa340a1193b6a7e7d65&_render=json&url=http://opensesamelabs.posterous.com/rss.xml"
				   store:kCacheStoreIndexNoFileCache
					name:nil
			  returnData:NO
			  identifier:1000
			  bufferSize:8192];
}

#pragma mark - DataHelper delegate

- (void)dataReceivedWith:(NSInteger)identifier andData:(NSData*)data andStatus:(NSInteger)status
{
	if (identifier == 1000 && data.length)
	{
		NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		self.entries = [[[json JSONValue] objectForKey:@"value"] objectForKey:@"items"];
		[json release];
		[tableView reloadData];
	}
}

- (void)dataReceived:(NSInteger)identifier withStatus:(NSInteger)status
{
	// MUST be images we need a refesh
	[tableView reloadData];
}

- (void)redirectReceived:(NSInteger)identifier withURL:(NSString*)url
{
}

- (void)errorReceived:(NSInteger)identifier withError:(NSError*)error
{
}

@end
