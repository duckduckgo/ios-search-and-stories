//
//  DDGWebViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGWebViewController.h"
#import "DDGAddressBarTextField.h"
#import "DDGBookmarksProvider.h"
#import "DDGNewsProvider.h"
#import "SVProgressHUD.h"
#import "ECSlidingViewController.h"
#import "DDGUnderViewController.h"
#import "DDGCache.h"
#import "DDGUtility.h"
#import "DDGStory.h"
#import "AFNetworking.h"
#import "DDGSettingsViewController.h"
#import "DDGActivityViewController.h"
#import "NSString+URLEncodingDDG.h"
#import "DDGBookmarkActivity.h"
#import "DDGReadabilityToggleActivity.h"

@implementation DDGWebViewController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	_webView.delegate = self;
	_webView.scalesPageToFit = YES;
	webViewLoadingDepth = 0;
    _webView.backgroundColor = [UIColor colorWithRed:0.204 green:0.220 blue:0.251 alpha:1.000];
    
    // if we already have a query or URL to load, load it.
	viewsInitialized = YES;
    if(queryOrURLToLoad)
        [self loadQueryOrURL:queryOrURLToLoad];
}

- (void)setSearchController:(DDGSearchController *)searchController {
    if (searchController == _searchController)
        return;
    
    _searchController = searchController;
    _searchController.state = DDGSearchControllerStateWeb;    
}

-(void)viewDidAppear:(BOOL)animated {
    UIMenuItem *searchMenuItem = [[UIMenuItem alloc] initWithTitle:@"Search"
                                                            action:@selector(search:)];
    [UIMenuController sharedMenuController].menuItems = @[searchMenuItem];
}

-(void)viewWillDisappear:(BOOL)animated {
    [UIMenuController sharedMenuController].menuItems = nil;
}

- (void)dealloc
{
    if (_webView.isLoading) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [_webView stopLoading];
    }
    
	_webView.delegate = nil;
	self.webViewURL = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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
    [_searchController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - Actions

-(void)searchControllerActionButtonPressed
{
    // strip extra params from DDG search URLs
    NSURL *shareURL = _webViewURL;
    NSString *query = [_searchController queryFromDDGURL:_webViewURL];
    if(query)
    {
        query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        shareURL = [NSURL URLWithString:[@"https://duckduckgo.com/?q=" stringByAppendingString:query]];
    }
    
    NSString *pageTitle = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSString *feed = [_webViewURL absoluteString];
    
    BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:_webViewURL];
    
    DDGBookmarkActivityItem *item = [DDGBookmarkActivityItem itemWithTitle:pageTitle URL:_webViewURL feed:feed];
    DDGBookmarkActivity *bookmarkActivity = [[DDGBookmarkActivity alloc] init];
    bookmarkActivity.bookmarkActivityState = (bookmarked) ? DDGBookmarkActivityStateUnsave : DDGBookmarkActivityStateSave;
    
    NSArray *applicationActivities = @[bookmarkActivity];
    
    if (nil != self.story) {
        DDGReadabilityToggleActivity *toggleActivity = [[DDGReadabilityToggleActivity alloc] init];
        applicationActivities = [applicationActivities arrayByAddingObject:toggleActivity];
    }
    
    DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:@[shareURL, item, self] applicationActivities:applicationActivities];
    [self presentViewController:avc animated:YES completion:NULL];
}

#pragma mark - Search handler

-(void)prepareForUserInput {
    if (self.searchController.searchField.window)
        [self.searchController.searchField becomeFirstResponder];
}

-(void)searchControllerLeftButtonPressed {        
	if(_webView.canGoBack)
        [_webView goBack];
	else
	    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadSelectedViewController];
}

-(void)searchControllerStopOrReloadButtonPressed {
    if(_webView.isLoading)
        [_webView stopLoading];
    else
        [_webView reload];
}

-(void)loadQueryOrURL:(NSString *)queryOrURLString
{
    if(!viewsInitialized)
	{
        // if views haven't loaded yet, nothing below work, so we need to save the URL/query to load later
        queryOrURLToLoad = queryOrURLString;
    }
	else if (queryOrURLString)
	{
        NSString *urlString;
        if([_searchController isQuery:queryOrURLString])
		{
			// direct query
            urlString = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&ko=-1&kl=%@",
						 [queryOrURLString URLEncodedStringDDG], 
						 [DDGCache objectForKey:DDGSettingRegion inCache:DDGSettingsCacheName]];
        }
		else
		{
			// a URL entered by user
            urlString = [_searchController validURLStringFromString:queryOrURLString];
		}
        
        NSURL *url = [NSURL URLWithString:urlString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		if ([[url host] hasSuffix:@"duckduckgo.com"])
			[request setValue:[DDGUtility agentDDG] forHTTPHeaderField:@"User-Agent"];
			
        [_webView loadRequest:request];
        [_searchController updateBarWithURL:url];
        self.webViewURL = url;
    }
}

- (void)loadJSONForStory:(DDGStory *)story completion:(void (^)(id JSON))completion {
    
    NSString *urlString = story.article_url;
    
    if (nil == urlString) {
        if (completion)
            completion(NULL);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion)
            completion(responseObject);
        if (--webViewLoadingDepth <= 0) {
            [_searchController webViewFinishedLoading];
            webViewLoadingDepth = 0;
            webViewLoadEvents = 0;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion)
            completion(nil);
        [_searchController webViewFinishedLoading];
        if (--webViewLoadingDepth <= 0) {
            [_searchController webViewFinishedLoading];
            webViewLoadingDepth = 0;
            webViewLoadEvents = 0;
        }
        [self loadQueryOrURL:[story url]];
    }];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (webViewLoadingDepth == 0) {
            webViewLoadingDepth++;
            webViewLoadEvents++;
            [_searchController webViewCanGoBack:NO];            
            [_searchController webViewStartedLoading];
        }
        
        [_searchController setProgress:(float) totalBytesRead / totalBytesExpectedToRead];
    }];
    
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/javascript"]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [operation start];
    });
}

- (NSString *)htmlFromJSON:(id)JSON {
    if ([JSON isKindOfClass:[NSArray class]]) {
        
        NSArray *stories = JSON;
        if ([stories count] > 0) {
            NSDictionary *dictionary = [stories objectAtIndex:0];
            if ([dictionary isKindOfClass:[NSDictionary class]]) {
                NSString *html = [dictionary objectForKey:@"html"];
                if ([html isKindOfClass:[NSString class]])
                    return html;
            }
        }
    }
    
    return nil;
}

-(void)loadStory:(DDGStory *)story {
    [self view];
    
    void (^htmlDownloaded)(BOOL success) = ^(BOOL success){
        if (success) {
            self.webViewURL = [NSURL URLWithString:story.url];
            [_webView loadRequest:[story HTMLURLRequest]];
        } else {
            [self loadQueryOrURL:[story url]];
        }
    };
    
    void (^completion)(id JSON) = ^(id JSON) {
        NSString *html = [self htmlFromJSON:JSON];
        if (nil != html) {
            [story writeHTMLString:html completion:htmlDownloaded];
        } else {
            htmlDownloaded(story.isHTMLDownloaded);
        }
        
        [DDGCache setObject:@(YES) forKey:story.storyID inCache:@"readStories"];        
    };
    
    self.story = story;
    
    if (!story.isHTMLDownloaded)
        [self loadJSONForStory:story completion:completion];
    else
        completion(nil);    
}

#pragma mark - Searching for selected text

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(action == @selector(search:))
        return ![_searchController.searchField isFirstResponder];
    else
        return [super canPerformAction:action withSender:sender];
}

-(void)search:(id)sender {
    NSString *selection = [self.webView stringByEvaluatingJavaScriptFromString:@"window.getSelection().toString()"];
    [self loadQueryOrURL:selection];
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
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)internalMailAction:(NSURL*)url
{
	if ([MFMailComposeViewController canSendMail])
	{
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:3];
        NSString *mailtoParameterString = [[url absoluteString] substringFromIndex:[@"mailto:" length]];
        NSUInteger questionMarkLocation = [mailtoParameterString rangeOfString:@"?"].location;
		
        if (questionMarkLocation == NSNotFound)
		{
			// simply a to parameter
			[params setObject:mailtoParameterString forKey:@"to"];
		}
		else
		{
			// more than just a to field
			[params setObject:[mailtoParameterString substringToIndex:questionMarkLocation] forKey:@"to"];
            NSString *parameterString = [mailtoParameterString substringFromIndex:questionMarkLocation + 1];
            NSArray *keyValuePairs = [parameterString componentsSeparatedByString:@"&"];
            for (NSString *queryString in keyValuePairs)
			{
                NSArray *keyValuePair = [queryString componentsSeparatedByString:@"="];
                if (keyValuePair.count == 2)
                    [params setObject:[[keyValuePair objectAtIndex:1] URLDecodedStringDDG] forKey:[[keyValuePair objectAtIndex:0] URLDecodedStringDDG]];
            }
        }
		// now mail it
		MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
		mailVC.mailComposeDelegate = self;
		if ([params objectForKey:@"to"])
			[mailVC setToRecipients:[[params objectForKey:@"to"] componentsSeparatedByString:@","]];
		else
			[mailVC setToRecipients:@[]];
		[mailVC setSubject:[params objectForKey:@"subject"]];
		[mailVC setMessageBody:[params objectForKey:@"body"] isHTML:YES];
		[self presentViewController:mailVC animated:YES completion:NULL];
	}
}

#pragma mark - Web view deleagte

- (void)updateBarWithRequest:(NSURLRequest *)request {
    NSURL *url = request.URL;
    
    if ([url isEqual:request.mainDocumentURL])
    {
        NSString *scheme = [[url scheme] lowercaseString];
        if ([scheme isEqualToString:@"http"]
            || [scheme isEqualToString:@"https"]) {
            [_searchController updateBarWithURL:request.URL];
            self.webViewURL = request.URL;
        } else if ([[[self.story HTMLURLRequest].URL URLByStandardizingPath] isEqual:[url URLByStandardizingPath]]) {
            NSURL *storyURL = [NSURL URLWithString:self.story.url];
            [_searchController updateBarWithURL:storyURL];
            self.webViewURL = storyURL;
        }
    }    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
		if ([[[request.URL scheme] lowercaseString] isEqualToString:@"mailto"])
		{
			// user is interested in mailing so use the internal mail API
			[self performSelector:@selector(internalMailAction:) withObject:request.URL afterDelay:0.005];
			return NO;
		}
	}
    
    [self updateBarWithRequest:request];
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
    webViewLoadEvents++;
    [self updateProgressBar];
    
    [_searchController webViewCanGoBack:theWebView.canGoBack];
    
	if (++webViewLoadingDepth == 1) {
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
        [_searchController webViewStartedLoading];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    webViewLoadEvents--;
    [self updateProgressBar];
    
    [self updateBarWithRequest:theWebView.request];
    [_searchController webViewCanGoBack:theWebView.canGoBack];
    
	if (--webViewLoadingDepth <= 0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [_searchController webViewFinishedLoading];
		webViewLoadingDepth = 0;
        webViewLoadEvents = 0;
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    webViewLoadEvents++;
    [self updateProgressBar];

	if (--webViewLoadingDepth <= 0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [_searchController webViewFinishedLoading];
		webViewLoadingDepth = 0;
        webViewLoadEvents = 0;
	}
}

-(void)updateProgressBar {
    if(webViewLoadEvents == 1)
        [_searchController setProgress:0.15];
    else if(webViewLoadEvents == 2)
        [_searchController setProgress:0.7];
}

@end
