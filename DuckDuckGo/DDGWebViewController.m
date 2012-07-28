//
//  DDGWebViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGWebViewController.h"
#import "DDGAddressBarTextField.h"

@implementation DDGWebViewController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

	_webView.delegate = self;
	_webView.scalesPageToFit = YES;
	webViewLoadingDepth = 0;
    _webView.backgroundColor = [UIColor colorWithRed:0.216 green:0.231 blue:0.235 alpha:1.000];
    
	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view];
    
	_searchController.searchHandler = self;
    _searchController.state = DDGSearchControllerStateWeb;
    [_searchController.searchButton setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];

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

#pragma mark - Address bar positioning
// TODO: clean up these methods
-(void)moveAddressBarOutOfWebViewAnimated:(BOOL)animated {
    static CGFloat headerHeight = 44.0;
    CGRect f;
    
    if(addressBarIsAnimating || !addressBarIsInside)
        return;
    addressBarIsInside = NO;
    addressBarIsAnimating = animated;

    
    // find the largest (tallest) subview in webview's scrollview
    UIView *mainSubview;
    for(int i=0; i < _webView.scrollView.subviews.count; i++) {
        UIView *subview = [[_webView.scrollView subviews] objectAtIndex:i];
        if(!mainSubview || subview.frame.size.height > mainSubview.frame.size.height)
            mainSubview = subview;
    }
    
    // actually add the search controller into the view heirarchy
    [_searchController.view removeFromSuperview];
    [self.view addSubview:_searchController.view];
    
    if(animated) {        
        // push the main subview up/down to accomodate the header
//        f = mainSubview.frame;
//        f.origin.y += -1*headerHeight;
//        mainSubview.frame = f;

        CGFloat headerOffset = -1*_webView.scrollView.contentOffset.y;
        if(headerOffset < -1*headerHeight)
            headerOffset = -1*headerHeight;

        // move the address bar up to where it used to be
        f = _searchController.view.frame;
        f.origin.y += headerOffset;
        _searchController.view.frame = f;


        f = _webView.frame;
        CGFloat offset = headerHeight + headerOffset;
        f.origin.y += offset;
        f.size.height -= offset;
        _webView.frame = f;
        
        f = mainSubview.frame;
        f.origin.y -= offset;
        mainSubview.frame = f;

        
        // move both the webView and the address bar down to where they should be
        
        [UIView animateWithDuration:0.3 animations:^{
            
            CGRect f = _searchController.view.frame;
            f.origin.y += -1*headerOffset;
            _searchController.view.frame = f;
            
            f = _webView.frame;
            CGFloat offset = -1*headerOffset;
            f.origin.y += offset;
            f.size.height -= offset;
            _webView.frame = f;
            
            f = mainSubview.frame;
            f.origin.y -= offset;
            mainSubview.frame = f;

//            
//            // move the webView down to fit the address bar
//        f = webView.frame;
//        CGFloat offset = headerHeight;
//        f.origin.y += offset;
//        f.size.height -= offset;
//        webView.frame = f;

        } completion:^(BOOL finished) {
            addressBarIsAnimating = NO;
            if(addressBarIsInside)
                [self moveAddressBarIntoWebViewAnimated:YES];
        }];
        
    } else {
        // push the main subview up/down to accomodate the header
        f = mainSubview.frame;
        f.origin.y += -1*headerHeight;
        mainSubview.frame = f;

        // move the webView down to fit the address bar
        f = _webView.frame;
        CGFloat offset = headerHeight;
        f.origin.y += offset;
        f.size.height -= offset;
        _webView.frame = f;
    }
}

-(void)moveAddressBarIntoWebViewAnimated:(BOOL)animated {
    static CGFloat headerHeight = 44.0;
    CGRect f;
    
    if(addressBarIsAnimating || addressBarIsInside)
        return;
    addressBarIsInside = YES;
    addressBarIsAnimating = animated;
        
    // find the largest (tallest) subview in webview's scrollviews
    UIView *mainSubview;
    for(int i=0; i < _webView.scrollView.subviews.count; i++) {
        UIView *subview = [[_webView.scrollView subviews] objectAtIndex:i];
        if(!mainSubview || subview.frame.size.height > mainSubview.frame.size.height)
            mainSubview = subview;
    }

    if(animated) {

        CGFloat headerOffset = -1*_webView.scrollView.contentOffset.y;
        if(headerOffset < -1*headerHeight)
            headerOffset = -1*headerHeight;

        [UIView animateWithDuration:0.3 animations:^{
            
            CGRect f = _searchController.view.frame;
            f.origin.y += headerOffset;
            _searchController.view.frame = f;
            
            f = _webView.frame;
            f.origin.y += headerOffset;
            f.size.height -= headerOffset;
            _webView.frame = f;
            
            f = mainSubview.frame;
            f.origin.y += -1*headerOffset;
            mainSubview.frame = f;
            
        } completion:^(BOOL finished){
            // actually add the search controller into the view heirarchy
            [_searchController.view removeFromSuperview];
            [_webView.scrollView addSubview:_searchController.view];
            [_webView.scrollView bringSubviewToFront:_searchController.view];
            
            CGRect f = _searchController.view.frame;
            f.origin.y = 0;
            _searchController.view.frame = f;
            
            f = _webView.frame;
            CGFloat offset = headerHeight + headerOffset;
            f.origin.y -= offset;
            f.size.height += offset;
            _webView.frame = f;
            
            f = mainSubview.frame;
            f.origin.y += offset;
            mainSubview.frame = f;
            
            addressBarIsAnimating = NO;
            if(!addressBarIsInside)
                [self moveAddressBarOutOfWebViewAnimated:YES];

        }];
    } else {
        // actually add the search controller into the view heirarchy
        [_searchController.view removeFromSuperview];
        [_webView.scrollView addSubview:_searchController.view];
        [_webView.scrollView bringSubviewToFront:_searchController.view];
        
        f = mainSubview.frame;
        f.origin.y += headerHeight;
        mainSubview.frame = f;
        
        f = _webView.frame;
        CGFloat offset = -1*headerHeight;
        f.origin.y += offset;
        f.size.height -= offset;
        _webView.frame = f;
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

    if([request.URL isEqual:request.mainDocumentURL])
        [_searchController updateBarWithURL:request.URL];
    
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
