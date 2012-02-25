//
//  DDGWebViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGWebViewController.h"

@implementation DDGWebViewController

@synthesize searchController;
@synthesize webView;
@synthesize params;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

	webView.delegate = self;
	webView.scalesPageToFit = YES;
	webViewLoadingDepth = 0;

	self.searchController = [[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view];
	searchController.searchHandler = self;
    searchController.state = DDGSearchControllerStateWeb;
    [searchController.searchButton setImage:[UIImage imageNamed:@"back_button.png"] forState:UIControlStateNormal];

    // if we already have a query or URL to load, load it.
	webViewInitialized = YES;
	if(webQuery)
        [self loadQuery:webQuery];
    else if(webURL)
        [self loadURL:webURL];
}

- (void)dealloc
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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


#pragma mark - Search handler

-(void)searchControllerLeftButtonPressed {
	if(webView.canGoBack)
		[webView goBack];
	else
	    [self.navigationController popViewControllerAnimated:NO];
}

-(void)searchControllerStopOrReloadButtonPressed {
    if(webView.isLoading)
        [webView stopLoading];
    else
        [webView reload];
}

-(void)loadQuery:(NSString *)query {
    NSString *url = [NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&ko=-1", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

    if(!webViewInitialized) {
        // if the view hasn't loaded yet, setting search text won't work, so we need to save the query to load later
        webQuery = query;
    } else if(query) {
        [self loadURL:url];
        searchController.searchField.text = query;
    }
}

-(void)loadURL:(NSString *)url {
    if(!webViewInitialized) {
        // if the view hasn't loaded yet, loading a URL won't work, so we need to save the URL to load later
        webURL = url;
    } else if(url) {
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        searchController.searchField.text = url;
    }
}

#pragma mark - web view deleagte

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([request.URL isEqual:request.mainDocumentURL])
        [searchController updateBarWithURL:request.URL];
    
    
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
	if (++webViewLoadingDepth == 1) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [searchController webViewStartedLoading];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
	if (--webViewLoadingDepth <= 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [searchController webViewFinishedLoading];
		webViewLoadingDepth = 0;
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	if (--webViewLoadingDepth <= 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [searchController webViewFinishedLoading];
		webViewLoadingDepth = 0;
	}
}

@end
