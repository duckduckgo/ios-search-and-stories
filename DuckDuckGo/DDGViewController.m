//
//  DDGViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/9/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGAppDelegate.h"
#import "DDGViewController.h"
#import "DDGWebViewController.h"
#import "AFNetworking.h"
#import "DDGCache.h"
#import <QuartzCore/QuartzCore.h>
#import "NSArray+ConcurrentIteration.h"
#import "DDGStoriesProvider.h"
#import "DDGSettingsViewController.h"

@interface DDGViewController (Private)
-(void)beginDownloadingStories;
-(void)downloadStoriesSuccess:(void (^)())success;
-(NSArray *)indexPathsofStoriesInArray:(NSArray *)newStories andNotArray:(NSArray *)oldStories;

-(NSURL *)faviconURLForDomain:(NSString *)domain;
-(UIImage *)grayscaleImageFromImage:(UIImage *)image;
-(void)loadFaviconForURLString:(NSString *)urlString storyID:(NSString *)storyID;

@end

@implementation DDGViewController

@synthesize loadedCell;
@synthesize tableView;
@synthesize searchController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view];
	searchController.searchHandler = self;
    searchController.state = DDGSearchControllerStateHome;
	[searchController.searchButton setImage:[UIImage imageNamed:@"settings_button.png"] forState:UIControlStateNormal];
    
    tableView.separatorColor = [UIColor clearColor];

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
    
    [self beginDownloadingStories];
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

    // if we animated out, animate back in
    if(tableView.alpha == 0) {
        tableView.transform = CGAffineTransformMakeScale(2, 2);
        [UIView animateWithDuration:0.3 animations:^{
            tableView.alpha = 1;
            tableView.transform = CGAffineTransformIdentity;
        }];
    }

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
	if (IPHONE)
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	else
        return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
        
    [searchController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];	
}

#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view {
    [self beginDownloadingStories];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view {
	return isRefreshing;
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view {
    return [DDGCache objectForKey:@"storiesUpdated" inCache:@"misc"];
}

#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    // this is the settings button, so let's load the settings controller
    DDGSettingsViewController *settingsVC = [[DDGSettingsViewController alloc] initWithDefaults];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentModalViewController:navController animated:YES];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {    
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    [webVC loadQueryOrURL:queryOrURL];
    
    // because we want the search bar to stay in place, we need to do custom animation here.
   
    [UIView animateWithDuration:0.3 animations:^{
        tableView.transform = CGAffineTransformMakeScale(2, 2);
        tableView.alpha = 0;
    } completion:^(BOOL finished) {
        tableView.transform = CGAffineTransformIdentity;
        [self.navigationController pushViewController:webVC animated:NO];
    }];
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

    NSArray *stories = [[DDGStoriesProvider sharedProvider] stories];
    NSDictionary *story = [stories objectAtIndex:indexPath.row];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:200];
	label.text = [story objectForKey:@"title"];
    if([[DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"readStories"] boolValue])
        label.textColor = [UIColor lightGrayColor];
    else
        label.textColor = [UIColor whiteColor];
    
    // load article image
    UIImageView *articleImageView = (UIImageView *)[cell.contentView viewWithTag:100];
    articleImageView.image = [UIImage imageWithData:[DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"storyImages"]];
    [articleImageView setContentMode:UIViewContentModeScaleAspectFill];
    // load site favicon image
    UIImageView *faviconImageView = (UIImageView *)[cell.contentView viewWithTag:300];
    faviconImageView.image = [UIImage imageWithData:[DDGCache objectForKey:[story objectForKey:@"id"] inCache:@"faviconImages"]];
    	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [DDGStoriesProvider sharedProvider].stories.count;
}

#pragma  mark - UITableViewDelegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *story = [[DDGStoriesProvider sharedProvider].stories objectAtIndex:indexPath.row];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // mark the story as read and make its image and favicon grayscale
        [DDGCache setObject:[NSNumber numberWithBool:YES] forKey:[story objectForKey:@"id"] inCache:@"readStories"];
        for(NSString *cache in [NSArray arrayWithObjects:@"storyImages", @"faviconImages", nil]) {
            NSData *imageData = [DDGCache objectForKey:[story objectForKey:@"id"] inCache:cache];
            UIImage *grayscaleImage = [self grayscaleImageFromImage:[UIImage imageWithData:imageData]];
            NSData *grayscaleData = UIImagePNGRepresentation(grayscaleImage);
            [DDGCache setObject:grayscaleData forKey:[story objectForKey:@"id"] inCache:cache];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5]; // wait for the animation to complete            
        });
    });

    NSString *escapedStoryURL = [[story objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self loadQueryOrURL:escapedStoryURL];
}

#pragma mark - Loading popular stories

// downloads stories asynchronously
-(void)beginDownloadingStories {
    isRefreshing = YES;
    
    [[DDGStoriesProvider sharedProvider] downloadStoriesInTableView:self.tableView success:^ {
        isRefreshing = NO;
        [refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];        
    }];
}

- (UIImage *)grayscaleImageFromImage:(UIImage *)image
{
    // Code from: iphonedevelopertips.com/graphics/convert-an-image-uiimage-to-grayscale.html
    
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [image CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}

@end
