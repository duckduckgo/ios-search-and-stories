//
//  DDGWebViewController.m
//  DuckDuckGo2
//
//  Created by Chris Heimark on 12/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DDGWebViewController.h"

@implementation DDGWebViewController

@synthesize searchController;
@synthesize www;
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

/**/
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.searchController = [[[DDGSearchController alloc] initWithNibName:@"DDGSearchController" view:self.view] autorelease];
	searchController.searchHandler = self;
    searchController.state = eViewStateWebResults;
	[searchController.searchButton setImage:[UIImage imageNamed:@"home40x37.png"] forState:UIControlStateNormal];
	
	NSURL *url = [params objectForKey:@"url"];
    if (!url)
        url = [NSURL URLWithString:@"https://duckduckgo.com"];
	
	[www loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)dealloc
{
    self.params = nil;
	self.searchController = nil;
	[super dealloc];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma - segue going down

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	
}

#pragma - search handler action happening

- (void)actionTaken:(NSDictionary*)action
{
	if ([[action objectForKey:@"action"] isEqualToString:@"home"])
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma - web view deleagte

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	
}

@end
