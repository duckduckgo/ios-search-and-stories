//
//  Instapaper.m
//  ChessyLib
//
//  Created by Chris Heimark on 1/28/11.
//  Copyright 2011 DuckDuckGo, Inc. All rights reserved.
//

/*
 URL: https://www.instapaper.com/api/add
 
 Parameters:
 
 username and password (Or you can pass the username and password via HTTP Basic Auth.)
 url
 title — optional, plain text, no HTML, UTF-8. If omitted or empty, Instapaper will crawl the URL to detect a title.
 selection — optional, plain text, no HTML, UTF-8. Will show up as the description under an item in the interface. 
			Some clients use this to describe where it came from, such as the text of the source Twitter post when
			sending a link from a Twitter client.
 redirect=close — optional. Specifies that, instead of returning the status code, the resulting page should show an 
			HTML “Saved!” notification that attempts to close its own window with Javascript after a short delay.
			This is useful if you’re sending people directly to /api/add URLs from a web application.

 jsonp — optional. See JSONP.
 */

#import "Instapaper.h"
#import "UtilityCHS.h"

@implementation Instapaper

- (id)initWithUser:(NSString*)user password:(NSString*)password title:(NSString*)title urlToLog:(NSString*)url
{
	self = [super init];
	if (self)
	{
		[UtilityCHS activityIndication:YES];
		
		NSArray *keyVals = [NSArray arrayWithObjects:
							@"POST",
							@"title", title,
							@"url", url,
							@"username", user,
							[password length] ? @"password": nil, password,
							nil];
		
		NSURLRequest *request = [UtilityCHS constructPostRequestWithURL:@"https://www.instapaper.com/api/add" argumentKeyValues:keyVals];
		
		(void)[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	}
	return self;
}

#pragma mark -
#pragma mark NSURLConnection delegate protocol callbacks

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// silently fail
	// turn off activity indication
	[UtilityCHS activityIndication:NO];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// turn off activity indication
	[UtilityCHS activityIndication:NO];
	
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	
}

@end
