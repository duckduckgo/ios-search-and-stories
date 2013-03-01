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
#import "SHK.h"
#import "ECSlidingViewController.h"
#import "DDGUnderViewController.h"
#import "DDGCache.h"
#import "DDGUtility.h"
#import "AFNetworking.h"

@implementation NSString (URLPrivateDDG)

- (NSString *)URLDecodedStringDDG
{
    return (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
}

- (NSString *)URLEncodedStringDDG
{
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																						(__bridge CFStringRef)self,
																						NULL,
																						CFSTR("!*'();:@&=$,/?%#[]"), // BUT NOT + 'cause we'll take care of that
																						kCFStringEncodingUTF8);
	return [s stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
}

@end

@implementation DDGWebViewController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	_webView.delegate = self;
	_webView.scalesPageToFit = YES;
	webViewLoadingDepth = 0;
    _webView.backgroundColor = [UIColor colorWithRed:0.204 green:0.220 blue:0.251 alpha:1.000];
    
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" containerViewController:self];
    
	_searchController.searchHandler = self;
    _searchController.state = DDGSearchControllerStateWeb;

    // if we already have a query or URL to load, load it.
	viewsInitialized = YES;
    if(queryOrURLToLoad)
        [self loadQueryOrURL:queryOrURLToLoad];
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
	_webView.delegate = nil;
    
    if (_webView.isLoading) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
        [_webView stopLoading];
    }
	
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

#pragma mark - Action sheet

-(void)searchControllerActionButtonPressed
{
    BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:_webViewURL];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  (bookmarked ? @"Unsave" : @"Save"),
                                  @"Share",
								  @"Open in Safari",
                                  nil];
    [actionSheet showInView:self.view];
}

/*
 1) if article from watrcoolr add internal favicon
 2) if search -- add the search favicon (not sure if this exists -- if not ask other chris)
 3) if other site we have no favicon -- just omit.
 */

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    NSString *pageTitle = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if(buttonIndex == 0)
	{
        // bookmark/unbookmark
                
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:_webViewURL];
        if(bookmarked)
            [[DDGBookmarksProvider sharedProvider] unbookmarkPageWithURL:_webViewURL];
        else
		{
			NSString *feed = [_webViewURL absoluteString];
			
			if ([feed hasPrefix:@"https://duckduckgo.com/?q="])
				// this is clearly a direct DDG search
				feed = @"search_icon.png";
			else
				// see if this is a news feed story that was bookmarked
				feed = [[DDGNewsProvider sharedProvider] feedForURL:feed];				

            [[DDGBookmarksProvider sharedProvider] bookmarkPageWithTitle:pageTitle feed:feed URL:_webViewURL];
		}
    
        [SVProgressHUD showSuccessWithStatus:(bookmarked ? @"Unsaved!" : @"Saved!")];
    }
	else if (buttonIndex == 1)
	{
        // share
        
        // strip extra params from DDG search URLs
        NSURL *shareURL = _webViewURL;
        NSString *query = [_searchController queryFromDDGURL:_webViewURL];
        if(query)
		{
            query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            shareURL = [NSURL URLWithString:[@"https://duckduckgo.com/?q=" stringByAppendingString:query]];
        }
        
        SHKItem *item = [SHKItem URL:shareURL title:pageTitle contentType:SHKURLContentTypeWebpage];
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
        [SHK setRootViewController:self];
        [actionSheet showInView:self.view];
    }
	else if (buttonIndex == 2)
	{
		// open in Safari
		[[UIApplication sharedApplication] openURL:_webViewURL];
	}
}


#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    
	if(_webView.canGoBack)
        [_webView goBack];
	else
	    [(DDGUnderViewController *)self.slidingViewController.underLeftViewController loadHomeViewController];
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
						 [DDGCache objectForKey:@"region" inCache:@"settings"]];
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
	[self dismissModalViewControllerAnimated:YES];
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
		[self presentModalViewController:mailVC animated:YES];
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
    webViewLoadEvents++;
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
