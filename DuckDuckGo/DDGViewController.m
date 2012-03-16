//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGViewController.h"
#import "DDGWebViewController.h"
#import "AFNetworking.h"

@interface DDGViewController (Private)
-(NSURL *)faviconURLForURLString:(NSString *)urlString;
@end

@implementation DDGViewController

@synthesize loadedCell;
@synthesize tableView;
@synthesize searchController;
@synthesize stories;

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
    searchController.state = DDGSearchControllerStateHome;
	[searchController.searchButton setImage:[UIImage imageNamed:@"settings_button.png"] forState:UIControlStateNormal];

    tableView.separatorColor = [UIColor whiteColor];
    
    NSData *storiesData = [NSData dataWithContentsOfFile:[self storiesPath]];
    if(!storiesData) // NSJSONSerialization complains if it's passed nil, so we give it an empty NSData instead
        storiesData = [NSData data];
    self.stories = [NSJSONSerialization JSONObjectWithData:storiesData options:0 error:nil];
    
    if (refreshHeaderView == nil) {
		refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                              arrowImageName:@"refresh_arrow.png"
                                                                   textColor:[UIColor colorWithWhite:1.0 alpha:0.0]];
		refreshHeaderView.delegate = self;
		[self.tableView addSubview:refreshHeaderView];
        [refreshHeaderView refreshLastUpdatedDate];
	}
	
	//  update the last update date
	[refreshHeaderView refreshLastUpdatedDate];
    
    [self downloadStories];
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
    
    [searchController resetOmnibar];
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

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];	
}

#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
    [self downloadStories];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{
	return isRefreshing; // should return if data source model is reloading
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
    NSDictionary *properties = [[NSFileManager defaultManager]
                                attributesOfItemAtPath:[self storiesPath]
                                error:nil];
    return [properties objectForKey:@"NSFileModificationDate"];
}

#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    // TODO: implement something here.
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {
    queryOrURLToLoad = queryOrURL;
    [self performSegueWithIdentifier:@"WebViewSegue" sender:self];
}

// i'll put this here for now because it's closely related to loadQuery:
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"WebViewSegue"] && queryOrURLToLoad)
        [segue.destinationViewController loadQueryOrURL:queryOrURLToLoad];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	static NSString *CellIdentifier = @"CurrentTopicCell";
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = loadedCell;
        self.loadedCell = nil;
	}

    NSDictionary *entry = [stories objectAtIndex:indexPath.row];

    // use a placeholder image for now, and append the article title to the URL to prevent caching
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:100];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[entry objectForKey:@"image"]] 
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                              timeoutInterval:20];
    [imageView setImageWithURLRequest:request placeholderImage:nil success:nil failure:nil];
    
    // load site favicon image
	UIImageView *siteFavicon = (UIImageView *)[cell.contentView viewWithTag:300];
    NSURL *siteFaviconURL = [self faviconURLForURLString:[entry objectForKey:@"url"]];
    NSURLRequest *siteFaviconRequest = [[NSURLRequest alloc] initWithURL:siteFaviconURL
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                                     timeoutInterval:20];
    [siteFavicon setImageWithURLRequest:siteFaviconRequest placeholderImage:nil success:nil failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"%@",error.userInfo);
    }];

    // load feed favicon image
    UIImageView *feedFavicon = (UIImageView *)[cell.contentView viewWithTag:400];
    NSURL *feedFaviconURL = [self faviconURLForURLString:[entry objectForKey:@"feed"]];
    if([feedFaviconURL isEqual:siteFaviconURL])
        feedFaviconURL = nil;
    NSURLRequest *feedFaviconRequest = [[NSURLRequest alloc] initWithURL:feedFaviconURL
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                                     timeoutInterval:20];
    [feedFavicon setImageWithURLRequest:feedFaviconRequest placeholderImage:nil success:nil failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"%@",error.userInfo);
    }];
    
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
	return [stories count];
}

#pragma  mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO (caine): this will be removed sooner or later before launch; they track with cookies.
    NSString *escapedStoryURL = [[[stories objectAtIndex:indexPath.row] objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // queryOrURLToLoad = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@",escapedStoryURL];
    queryOrURLToLoad = escapedStoryURL;
    [self performSegueWithIdentifier:@"WebViewSegue" sender:self];
}

#pragma mark - Loading popular stories

- (void)downloadStories {
    // start downloading new stories
    isRefreshing = YES;
    
    NSURL *url = [NSURL URLWithString:@"http://nil.duckduckgo.com/watrcoolr.js?o=json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSArray *newStories = (NSArray *)JSON;

        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:[self indexPathsofStoriesInArray:newStories andNotArray:self.stories] 
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView deleteRowsAtIndexPaths:[self indexPathsofStoriesInArray:self.stories andNotArray:newStories] 
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
        self.stories = newStories;
        [self.tableView endUpdates];

        NSData *data = [NSJSONSerialization dataWithJSONObject:self.stories 
                                                       options:0 
                                                         error:nil];
        [data writeToFile:[self storiesPath] atomically:YES];
        
        isRefreshing = NO;
        [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"FAILURE: %@",[error userInfo]);
    }];
    [operation start];
}

-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    
    for(int i=0;i<newStories.count;i++) {
        NSString *storyID = [[newStories objectAtIndex:i] objectForKey:@"id"];

        BOOL matchFound = NO;
        for(NSDictionary *oldStory in oldStories) {
            if([storyID isEqualToString:[oldStory objectForKey:@"id"]]) {
                matchFound = YES;
                break;
            }
        }
        
        if(!matchFound)
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    return [indexPaths copy];
}

-(NSString *)storiesPath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"stories.plist"];
}

-(NSURL *)faviconURLForURLString:(NSString *)urlString {
    if(!urlString || [urlString isEqual:[NSNull null]])
        return nil;
    // http://i2.duck.co/i/reddit.com.ico
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *faviconURLString = [NSString stringWithFormat:@"http://i2.duck.co/i/%@.ico",[url host]];
    return [NSURL URLWithString:faviconURLString];
}

@end
