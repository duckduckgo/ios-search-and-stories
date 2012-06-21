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
#import <QuartzCore/QuartzCore.h>

@interface DDGViewController (Private)
-(NSURL *)faviconURLForDomain:(NSString *)domain;
-(UIImage *)grayscaleImageFromImage:(UIImage *)image;
-(void)loadFaviconForURLString:(NSString *)urlString intoImageView:(UIImageView *)imageView success:(void (^)(UIImage *image))success;
-(void)loadFaviconForDomain:(NSString *)domain intoImageView:(UIImageView *)imageView success:(void (^)(UIImage *image))success;
-(BOOL)image:(UIImage *)image1 isEqualToImage:(UIImage *)image2;
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

- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view];
	searchController.searchHandler = self;
    searchController.state = DDGSearchControllerStateHome;
	[searchController.searchButton setImage:[UIImage imageNamed:@"settings_button.png"] forState:UIControlStateNormal];
    
    tableView.separatorColor = [UIColor clearColor];
    
    readStories = [NSMutableDictionary dictionaryWithContentsOfFile:self.readStoriesPath];
    if(!readStories)
        readStories = [[NSMutableDictionary alloc] init];
    
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

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
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
    // this is the settings button, so let's load the settings controller
    IASKAppSettingsViewController *settings = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
    settings.delegate = self;
    settings.showDoneButton = YES;
    settings.showCreditsFooter = NO; // TODO: make sure to give everyone credit elsewhere in an info page or something
    
    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:settings];
    [self presentModalViewController:aNavController animated:NO];
}

-(void)loadQueryOrURL:(NSString *)queryOrURL {    
    DDGWebViewController *webVC = [[DDGWebViewController alloc] initWithNibName:nil bundle:nil];
    [webVC loadQueryOrURL:queryOrURL];
    
    // because we want the search bar to stay in place, we need to do custom animation here.
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = tableView.frame;
        frame.origin.x -= frame.size.width;
        tableView.frame = frame;
    } completion:^(BOOL finished) {
        CGRect frame = tableView.frame;
        frame.origin.x += frame.size.width;
        tableView.frame = frame;

        [self.navigationController pushViewController:webVC animated:NO];
    }];
}

#pragma mark - Settings delegate

-(void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self dismissModalViewControllerAnimated:YES];
    [DDGAppDelegate processSettingChanges];
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
        
        // one-time cell setup that can't be done in interface builder:
        UIView *imageView = [cell viewWithTag:100];
        imageView.layer.masksToBounds = YES;
        
        UIBezierPath *topCornersMaskPath = [UIBezierPath bezierPathWithRoundedRect:imageView.bounds 
                                                       byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight
                                                             cornerRadii:CGSizeMake(4.0, 4.0)];
        CAShapeLayer *topCornersMaskLayer = [CAShapeLayer layer];
        topCornersMaskLayer.frame = imageView.bounds;
        topCornersMaskLayer.path = topCornersMaskPath.CGPath;
        imageView.layer.mask = topCornersMaskLayer;
    
        UIView *labelBackground = [cell viewWithTag:400];
        
        UIBezierPath *bottomCornersMaskPath = [UIBezierPath bezierPathWithRoundedRect:labelBackground.bounds 
                                                                 byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight
                                                                       cornerRadii:CGSizeMake(4.0, 4.0)];
        CAShapeLayer *bottomCornersMaskLayer = [CAShapeLayer layer];
        bottomCornersMaskLayer.frame = labelBackground.bounds;
        bottomCornersMaskLayer.path = bottomCornersMaskPath.CGPath;
        labelBackground.layer.mask = bottomCornersMaskLayer;
        
        labelBackground.backgroundColor = [UIColor clearColor];
        CAGradientLayer *gradient = [CAGradientLayer layer]; 
        gradient.frame = labelBackground.bounds; 
        gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor colorWithWhite:0.98 alpha:1.0] CGColor],
                           (id)[[UIColor colorWithWhite:0.90 alpha:1.0] CGColor],
                           nil];
        [labelBackground.layer addSublayer:gradient];
	}

    NSDictionary *entry = [stories objectAtIndex:indexPath.row];

    UILabel *label = (UILabel *)[cell.contentView viewWithTag:200];
	label.text = [entry objectForKey:@"title"];
    if([[readStories objectForKey:[entry objectForKey:@"id"]] boolValue])
        label.textColor = [UIColor lightGrayColor];
    else
        label.textColor = [UIColor darkGrayColor];
    
    // load article image
    UIImageView *articleImageView = (UIImageView *)[cell.contentView viewWithTag:100];
    articleImageView.image = nil; // clear any old image that might have been there
    NSURLRequest *articleImageRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[entry objectForKey:@"image"]] 
                                                              cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                                          timeoutInterval:20];
    AFHTTPRequestOperation *articleImageOperation = [[AFHTTPRequestOperation alloc] initWithRequest:articleImageRequest];
    [articleImageOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        UIImage *image = [UIImage imageWithData:responseObject];
        if([[readStories objectForKey:[entry objectForKey:@"id"]] boolValue]) {
            UIImage *grayscaleImage = [self grayscaleImageFromImage:image];
            articleImageView.image = grayscaleImage;
        } else {
            articleImageView.image = image;
        }
        
    } failure:nil];
    [articleImageOperation start];
        
    // load site favicon image
    UIImageView *faviconImageView = (UIImageView *)[cell.contentView viewWithTag:300];
    [self loadFaviconForURLString:[entry objectForKey:@"url"] intoImageView:faviconImageView success:^(UIImage *image) {
        // if this article has been read, load the grayscale version of the favicon...
        if([[readStories objectForKey:[entry objectForKey:@"id"]] boolValue]) {
            UIImage *grayscaleImage = [self grayscaleImageFromImage:image];
            faviconImageView.image = grayscaleImage;
        }
        // ... if not, don't do anything (the color version has already been loaded)
    }];
    	
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

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *entry = [stories objectAtIndex:indexPath.row];
    
    [readStories setObject:[NSNumber numberWithBool:YES] forKey:[entry objectForKey:@"id"]];
    [tableView reloadData];
    [readStories writeToFile:self.readStoriesPath atomically:YES];

    NSString *escapedStoryURL = [[entry objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self loadQueryOrURL:escapedStoryURL];
}

#pragma mark - Loading popular stories

- (void)downloadStories {
    // start downloading new stories
    isRefreshing = YES;
    
    NSURL *url = [NSURL URLWithString:@"http://caine.duckduckgo.com/watrcoolr.js?o=json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSArray *newStories = (NSArray *)JSON;

        NSArray *addedStories = [self indexPathsofStoriesInArray:newStories andNotArray:self.stories];
        NSArray *removedStories = [self indexPathsofStoriesInArray:self.stories andNotArray:newStories];
        
        // update the stories array
        self.stories = newStories;
        
        // update the table view with added and removed stories
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:addedStories 
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView deleteRowsAtIndexPaths:removedStories 
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        
        // TODO: Remove this before public release
        NSData *data;
        @try {
            data = [NSJSONSerialization dataWithJSONObject:self.stories 
                                                           options:0 
                                                             error:nil];
        }
        @catch (NSException *exception) {
            NSLog(@"Could not update stories, probably watrcoolr's fault.");
            data = [NSData data];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not update stories, probably watrcoolr's fault." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
            [alert show];
        }
        
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
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"stories.json"];
}

-(NSString *)readStoriesPath {
   return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"readStories.plist"];
}

                   
-(NSURL *)faviconURLForDomain:(NSString *)domain {
    // http://i2.duck.co/i/reddit.com.ico
    NSString *faviconURLString = [NSString stringWithFormat:@"http://i2.duck.co/i/%@.ico",domain];
    return [NSURL URLWithString:faviconURLString];
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

-(void)loadFaviconForURLString:(NSString *)urlString intoImageView:(UIImageView *)imageView success:(void (^)(UIImage *image))success {
    if(!urlString || [urlString isEqual:[NSNull null]])
        return;
    [self loadFaviconForDomain:[[NSURL URLWithString:urlString] host] intoImageView:imageView success:(void (^)(UIImage *image))success];
}

-(void)loadFaviconForDomain:(NSString *)domain intoImageView:(UIImageView *)imageView success:(void (^)(UIImage *image))success {
    NSMutableArray *domainParts = [[domain componentsSeparatedByString:@"."] mutableCopy];
    [domainParts removeObjectAtIndex:0];
    if(domainParts.count == 0)
        return; // we're definitely down to just a TLD by now and still couldn't get a favicon.
    NSString *newDomain = [domainParts componentsJoinedByString:@"."];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[self faviconURLForDomain:domain]
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad 
                                              timeoutInterval:20];
    
    __block UIImageView *blockImageView = imageView;

    [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request , NSHTTPURLResponse *response , UIImage *image) {
        if([image size].width > 1) {
            // image loaded successfully; we're done here.
            if(success)
                success(image);
            return;
        }
        [self loadFaviconForDomain:newDomain intoImageView:blockImageView success:(void (^)(UIImage *image))success];
        blockImageView = nil;
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [self loadFaviconForDomain:newDomain intoImageView:blockImageView success:(void (^)(UIImage *image))success];
        blockImageView = nil;
    }];
}

-(BOOL)image:(UIImage *)image1 isEqualToImage:(UIImage *)image2 {
    // slow, inefficient solution, but it might be fast enough anyway.
    return [UIImagePNGRepresentation(image1) isEqualToData:UIImagePNGRepresentation(image2)];
}

@end
