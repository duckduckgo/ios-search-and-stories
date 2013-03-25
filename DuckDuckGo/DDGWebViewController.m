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
#import "SVProgressHUD.h"
#import "ECSlidingViewController.h"
#import "DDGUnderViewController.h"
#import "DDGUtility.h"
#import "DDGStory.h"
#import "AFNetworking.h"
#import "DDGSettingsViewController.h"
#import "DDGActivityViewController.h"
#import "NSString+URLEncodingDDG.h"
#import "DDGBookmarkActivity.h"
#import "DDGReadabilityToggleActivity.h"

@interface DDGWebViewController ()
@property (nonatomic, readwrite) BOOL inReadabilityMode;
@end

@implementation DDGWebViewController

#pragma mark - View lifecycle

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);    
}

- (UIWebView *)webView {
    if (nil == _webView) {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        webView.delegate = self;
        
        webView.scalesPageToFit = YES;
        _webViewLoadingDepth = 0;
        webView.backgroundColor = [UIColor colorWithRed:0.204 green:0.220 blue:0.251 alpha:1.000];
        
        [self.view addSubview:webView];
        _webView = webView;
    }
        
    return _webView;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
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
    if (self.webView.isLoading) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [self.webView stopLoading];
    }
    
	self.webView.delegate = nil;
    self.webView = nil;
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

#pragma mark - Readability Mode

- (BOOL)currentURLIsNonReadabilityURL {
    return [self.story.URL isEqual:self.webView.request.URL];
}

- (BOOL)canSwitchToReadabilityMode {
    if (self.inReadabilityMode)
        return NO;

    BOOL readabilityAvailable = (nil != self.story.articleURLString);
    
    return (readabilityAvailable && !self.webView.canGoBack);
}

- (void)switchReadabilityMode:(BOOL)on {
    if (on) {
        if (![self canSwitchToReadabilityMode])
            return;
        
            [self loadStory:self.story readabilityMode:YES];
    } else {
        if (!self.inReadabilityMode)
            return;
        
            [self loadStory:self.story readabilityMode:NO];
    }
}

#pragma mark - Actions

-(void)searchControllerActionButtonPressed
{
    // strip extra params from DDG search URLs
    NSURL *shareURL = self.webViewURL;
    NSString *query = [_searchController queryFromDDGURL:shareURL];
    if(query)
    {
        query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        shareURL = [NSURL URLWithString:[@"https://duckduckgo.com/?q=" stringByAppendingString:query]];
    }
    
    NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSString *feed = [self.webViewURL absoluteString];
    
    NSArray *applicationActivities = @[];
    NSArray *items = @[shareURL, self];
    
    DDGBookmarkActivity *bookmarkActivity = nil;
    DDGBookmarkActivityItem *bookmarkItem = nil;
    
    if (nil != self.story && !self.webView.canGoBack) {
        bookmarkActivity = [[DDGBookmarkActivity alloc] init];
        bookmarkItem = [DDGBookmarkActivityItem itemWithStory:self.story];
        bookmarkActivity.bookmarkActivityState = (self.story.savedValue) ? DDGBookmarkActivityStateUnsave : DDGBookmarkActivityStateSave;
    } else if ([self.searchController isQuery:self.searchController.searchField.text]) {
        bookmarkActivity = [[DDGBookmarkActivity alloc] init];        
        bookmarkItem = [DDGBookmarkActivityItem itemWithTitle:pageTitle URL:self.webViewURL feed:feed];
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:self.webViewURL];
        bookmarkActivity.bookmarkActivityState = (bookmarked) ? DDGBookmarkActivityStateUnsave : DDGBookmarkActivityStateSave;
    }
    
    if (nil != bookmarkActivity && bookmarkItem != nil) {
        applicationActivities = [applicationActivities arrayByAddingObject:bookmarkActivity];
        items = [items arrayByAddingObject:bookmarkItem];
    }
    
    if (self.inReadabilityMode) {
        DDGReadabilityToggleActivity *toggleActivity = [[DDGReadabilityToggleActivity alloc] init];
        toggleActivity.toggleMode = DDGReadabilityToggleModeOff;
        applicationActivities = [applicationActivities arrayByAddingObject:toggleActivity];
    } else if ([self canSwitchToReadabilityMode]) {
        DDGReadabilityToggleActivity *toggleActivity = [[DDGReadabilityToggleActivity alloc] init];
        toggleActivity.toggleMode = DDGReadabilityToggleModeOn;
        applicationActivities = [applicationActivities arrayByAddingObject:toggleActivity];
    }
    
    DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:items applicationActivities:applicationActivities];
    [self presentViewController:avc animated:YES completion:NULL];
}

#pragma mark - Search handler

-(void)prepareForUserInput {
    if (self.searchController.searchField.window)
        [self.searchController.searchField becomeFirstResponder];
}

-(void)searchControllerLeftButtonPressed {        
	if(self.webView.canGoBack)
        [self.webView goBack];
	else
	    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadSelectedViewController];
}

-(void)searchControllerStopOrReloadButtonPressed {
    if(self.webView.isLoading)
        [self.webView stopLoading];
    else
        [self.webView reload];
}

-(void)loadQueryOrURL:(NSString *)queryOrURLString
{
    [self view];
    
    NSString *urlString;
    if([_searchController isQuery:queryOrURLString])
    {
        // direct query
        urlString = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&ko=-1&kl=%@",
                     [queryOrURLString URLEncodedStringDDG], 
                     [[NSUserDefaults standardUserDefaults] objectForKey:DDGSettingRegion]];
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
        
    [self.webView loadRequest:request];
    [_searchController updateBarWithURL:url];
    self.webViewURL = url;
}

- (void)loadJSONForStory:(DDGStory *)story completion:(void (^)(id JSON))completion {
    
    NSString *urlString = story.articleURLString;
    
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
        if (--_webViewLoadingDepth <= 0) {
            [_searchController webViewFinishedLoading];
            _webViewLoadingDepth = 0;
            _webViewLoadEvents = 0;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion)
            completion(nil);
        [_searchController webViewFinishedLoading];
        if (--_webViewLoadingDepth <= 0) {
            [_searchController webViewFinishedLoading];
            _webViewLoadingDepth = 0;
            _webViewLoadEvents = 0;
        }
        [self loadQueryOrURL:story.urlString];
    }];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (_webViewLoadingDepth == 0) {
            _webViewLoadingDepth++;
            _webViewLoadEvents++;
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

-(void)loadStory:(DDGStory *)story readabilityMode:(BOOL)readabilityMode {
    [self view];
    
    if (nil != self.webView.request) {
        [self.webView removeFromSuperview];
        
        if (self.webView.isLoading) {
            [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
            [self.webView stopLoading];
        }
        
        self.webView.delegate = nil;
        self.webView = nil;        
    }
    
    void (^htmlDownloaded)(BOOL success) = ^(BOOL success){
        if (readabilityMode && success) {
            self.webViewURL = story.URL;
            [self.webView loadHTMLString:[story HTML] baseURL:nil];
        } else {
            [self loadQueryOrURL:story.urlString];
        }
    };
    
    void (^completion)(id JSON) = ^(id JSON) {
        NSString *html = [self htmlFromJSON:JSON];
        if (nil != html) {
            [story writeHTMLString:html completion:htmlDownloaded];
        } else {
            htmlDownloaded(story.isHTMLDownloaded);
        }
        
        story.readValue = YES;
        
        NSManagedObjectContext *context = story.managedObjectContext;
        [context performBlock:^{
            NSError *error = nil;
            BOOL success = [context save:&error];
            if (!success)
                NSLog(@"error: %@", error);
        }];
    };
    
    self.story = story;
    
    if (readabilityMode && !story.isHTMLDownloaded)
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
            self.inReadabilityMode = NO;
        } else if ((self.story && !self.webView.canGoBack)
                   || [[[self.story HTMLURLRequest].URL URLByStandardizingPath] isEqual:[url URLByStandardizingPath]]) {
            NSURL *storyURL = self.story.URL;
            [_searchController updateBarWithURL:storyURL];
            self.webViewURL = storyURL;
            self.inReadabilityMode = YES;
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
    
    // NSLog(@"shouldStartLoadWithRequest: %@ navigationType: %i", request, navigationType);
    
    [self updateBarWithRequest:request];
    
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
    _webViewLoadEvents++;
    [self updateProgressBar];
    
//    NSLog(@"webViewDidStartLoad events: %i", _webViewLoadEvents);
    
    [_searchController webViewCanGoBack:theWebView.canGoBack];
    
	if (++_webViewLoadingDepth == 1) {
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
        [_searchController webViewStartedLoading];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{    
    _webViewLoadEvents--;
    [self updateProgressBar];
    
    [self updateBarWithRequest:theWebView.request];
    [_searchController webViewCanGoBack:theWebView.canGoBack];
        
	if (--_webViewLoadingDepth <= 0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [_searchController webViewFinishedLoading];
		_webViewLoadingDepth = 0;
        _webViewLoadEvents = 0;
	}
    
//    NSLog(@"webViewDidFinishLoad events: %i", _webViewLoadEvents);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    _webViewLoadEvents--;
    [self updateProgressBar];

	if (--_webViewLoadingDepth <= 0) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [_searchController webViewFinishedLoading];
		_webViewLoadingDepth = 0;
        _webViewLoadEvents = 0;
	}
    
//    NSLog(@"didFailLoadWithError events: %i", _webViewLoadEvents);
}

-(void)updateProgressBar {
    if(_webViewLoadEvents == 1)
        [_searchController setProgress:0.15];
    else if(_webViewLoadEvents == 2)
        [_searchController setProgress:0.7];
}

@end
