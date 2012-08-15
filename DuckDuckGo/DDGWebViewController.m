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
#import "SHK.h"
#import "ECSlidingViewController.h"
@implementation DDGWebViewController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	_webView.delegate = self;
	_webView.scalesPageToFit = YES;
	webViewLoadingDepth = 0;
    _webView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen_bg.png"]];
    
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
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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

-(void)searchControllerActionButtonPressed {
    BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:webViewURL];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  (bookmarked ? @"Unsave" : @"Save"),
                                  @"Share",
                                  nil];
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    NSString *pageTitle = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if(buttonIndex == 0) {
        // bookmark/unbookmark
                
        BOOL bookmarked = [[DDGBookmarksProvider sharedProvider] bookmarkExistsForPageWithURL:webViewURL];
        if(bookmarked)
            [[DDGBookmarksProvider sharedProvider] unbookmarkPageWithURL:webViewURL];
        else
            [[DDGBookmarksProvider sharedProvider] bookmarkPageWithTitle:pageTitle URL:webViewURL];
    
        [SVProgressHUD showSuccessWithStatus:(bookmarked ? @"Unsaved!" : @"Saved!")];
    } else if(buttonIndex == 1) {
        // share
        
        // strip extra params from DDG search URLs
        NSURL *shareURL = webViewURL;
        NSString *query = [_searchController queryFromDDGURL:webViewURL];
        if(query) {
            query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            shareURL = [NSURL URLWithString:[@"https://duckduckgo.com/?q=" stringByAppendingString:query]];
        }
        
        SHKItem *item = [SHKItem URL:shareURL title:pageTitle contentType:SHKURLContentTypeWebpage];
        SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
        [SHK setRootViewController:self];
        [actionSheet showInView:self.view];
    }
}


#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
    
	if(_webView.canGoBack)
        [_webView goBack];
	else
	    [self.navigationController popViewControllerAnimated:NO];
}

-(void)searchControllerStopOrReloadButtonPressed {
    if(_webView.isLoading)
        [_webView stopLoading];
    else
        [_webView reload];
}

-(void)loadQueryOrURL:(NSString *)queryOrURLString {
    if(!viewsInitialized) {
        // if views haven't loaded yet, nothing below work, so we need to save the URL/query to load later
        queryOrURLToLoad = queryOrURLString;
    } else if(queryOrURLString) {
        NSString *urlString;
        if([_searchController isQuery:queryOrURLString]) {
            urlString = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&ko=-1", [queryOrURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        } else
            urlString = [_searchController validURLStringFromString:queryOrURLString];
        
        NSURL *url = [NSURL URLWithString:urlString];
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
        [_searchController updateBarWithURL:url];
        webViewURL = url;
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

#pragma mark - Web view deleagte

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    if([request.URL isEqual:request.mainDocumentURL]) {
        [_searchController updateBarWithURL:request.URL];
        webViewURL = request.URL;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
    webViewLoadEvents++;
    [self updateProgressBar];
    
	if (++webViewLoadingDepth == 1) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [_searchController webViewStartedLoading];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    webViewLoadEvents++;
    [self updateProgressBar];
    
	if (--webViewLoadingDepth <= 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
