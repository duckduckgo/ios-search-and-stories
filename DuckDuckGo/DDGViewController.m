//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGViewController.h"
#import "DDGWebViewController.h"
#import "DDGTopicsTrendsPick.h"
#import "UtilityCHS.h"
#import "SBJson.h"

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
	
	dataHelper = [[DataHelper alloc] initWithDelegate:self];
	
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view];
	searchController.searchHandler = self;
    searchController.state = eViewStateHome;
	[searchController.searchButton setImage:[UIImage imageNamed:@"gear40x37.png"] forState:UIControlStateNormal];
	
	UILabel *lbl = (UILabel*)[self.view viewWithTag:100];
	lbl.text = NSLocalizedString (@"Customize", nil);

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

#pragma mark - user actions

- (IBAction)customize:(id)sender
{
	DDGTopicsTrendsPick *ttp = [self.storyboard instantiateViewControllerWithIdentifier:@"TopicsTrendsPick"];
	
	
	[self.navigationController pushViewController:ttp animated:YES];
}


#pragma mark - search handler action happening

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
	UIImageView		*iv;
	
	static NSString *CellIdentifier = @"CurrentTopicCell";
	
	cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
        [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = loadedCell;
        self.loadedCell = nil;
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		iv = (UIImageView *)[cell.contentView viewWithTag:100];
		iv.contentMode = UIViewContentModeScaleAspectFill;
		iv.clipsToBounds = YES;
	}
	NSDictionary *entry = [entries objectAtIndex:indexPath.row];
	id mc = [entry objectForKey:@"media:content"];
	
	iv = (UIImageView *)[cell.contentView viewWithTag:100];
	
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
	NSDictionary *entry = [entries objectAtIndex:indexPath.row];
	
	NSString *urlString = [entry objectForKey:@"link"];
	
	if (urlString)
	{
		DDGWebViewController *wvc = [self.storyboard instantiateViewControllerWithIdentifier:@"WebView"];
		
		urlString = [UtilityCHS fixupURL:urlString];
		
		wvc.params = [NSDictionary dictionaryWithObjectsAndKeys:
					  [NSURL URLWithString:urlString], @"homeScreenLink", 
					  nil];
		
		[self.navigationController pushViewController:wvc animated:YES];
	}
}

#pragma - load up entries for  home screen

- (UIImage*)loadImage:(NSString*)url
{
	NSData *img = [dataHelper retrieve:url
								 cache:kCacheIDImages
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
				   cache:kCacheIDNoFileCache
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
