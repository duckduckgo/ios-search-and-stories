//
//  DataHelper.m
//
//  Created by Chris Heimark on 10/13/09.
//  Copyright 2009 DuckDuckGo, Inc. All rights reserved.
//

#import "DataHelper.h"
#include "CacheController.h"

#pragma mark - Private FileFetch interface

@interface FileFetch : NSObject 
{
	NSMutableData *receivedData;
	NSString *name;
	
	NSString *cache;
	
	id<DataHelperDelegate> delegate;
	NSURLConnection *urlConnection;
	id controlSet;
	NSInteger identifier;
	NSInteger statusCode;
}

@property (nonatomic, strong) NSString *cache;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger identifier;

-(id)initWithDelegate:(id<DataHelperDelegate>)delegate andControlSet:(id)control bufferSize:(NSUInteger)capacity;
-(id)retrieve:(id)urlOrRequest cache:(NSString *)cacheID name:(NSString*)theName identifier:(NSInteger)ID;
-(void)cleanup;

@end

#pragma mark - Data Helper

@implementation DataHelper

NSDictionary *HTTPHeaders = nil;

#pragma mark Class management

+ (void)initialize
{
    HTTPHeaders = [[NSDictionary alloc] init];
}

+(void)setHTTPHeaders:(NSDictionary *)headers {
    HTTPHeaders = [headers copy];
}

- (id)initWithDelegate:(id<DataHelperDelegate>)receiptDelegate
{
    if ((self = [super init]))
	{
        // data comes in here
		delegate = receiptDelegate;
		connections = [[NSMutableSet alloc] initWithCapacity:16];
    }
    return self;
}

- (void)dealloc
{
    // close any open connections; everything else takes care of itself.
	[self flushAllIO];
}

#pragma mark Handling data requests


// TODO: [ishaan] see if this can be modified to use blocks
- (NSData*)retrieve:(id)urlOrRequest cache:(NSString *)cacheID name:(NSString*)name returnData:(BOOL)returnData identifier:(NSInteger)ID  bufferSize:(NSUInteger)capacity
{
    NSLog(@"retrieve: called");
	// ignore any redundant requests for the same items
	if ([self isRequestOutstandingForCache:cacheID name:name identifier:ID])
		return nil;
	
	if ([cacheID isEqualToString:kCacheIDNoFileCache])
		// no cache case -- always GET
		;
	else if ([CacheController lifetimeSecondsForCache:cacheID] || !urlOrRequest)
	{		
        if([CacheController entryExistsForCache:cacheID entry:name]) {
            if(returnData)
                return [CacheController dataForCache:cacheID entry:name];
            else
                return nil;
        }
        
        if(!urlOrRequest) {
            // we weren't given any resource URL to fall back on, so we can't attempt to fetch the file.
            return nil;
        }
	}
	
	// attempt to actually fetch the file here
	FileFetch *fetchItem = [[FileFetch alloc] initWithDelegate:delegate andControlSet:connections bufferSize:capacity];
	if (fetchItem)
	{
		// remember this outstanding request
		[connections addObject:fetchItem];
		// and make the request
		[fetchItem retrieve:urlOrRequest cache:cacheID name:name identifier:ID];
	}
	return nil;
}

#pragma mark IO management

//// methods to manually clean up stuff
-(void)flushAllIO
{
	NSSet *snapshot = (NSSet*)[connections allObjects];
	// manually flush all standing IO
	for (FileFetch *outstanding in snapshot)
		[outstanding cleanup];
}

- (BOOL)isRequestOutstandingForCache:(NSString *)cacheID name:(NSString*)name identifier:(NSInteger)ID
{
	NSSet *snapshot = (NSSet*)[connections allObjects];
	for (FileFetch *outstanding in snapshot)
		if ([outstanding.cache isEqualToString:cacheID] && outstanding.identifier == ID && [outstanding.name isEqualToString:name])
			return YES;
	
	return NO;
}

@end

#pragma mark - FileFetch

@implementation FileFetch

@synthesize identifier;
@synthesize cache;
@synthesize name;

- (id)initWithDelegate:(id<DataHelperDelegate>)receiptDelegate  andControlSet:(id)control bufferSize:(NSUInteger)capacity
{
    if ((self = [super init]))
	{
        // data comes in here
		receivedData = [[NSMutableData alloc] initWithCapacity:capacity];
		delegate = receiptDelegate;
		controlSet = control;
    }
    return self;
}


- (id)retrieve:(id)urlOrRequest cache:(NSString *)cacheID name:(NSString *)theName identifier:(NSInteger)ID
{
	self.cache = cacheID;
	self.identifier = ID;
	self.name = theName;
	
	NSMutableURLRequest *request;
	if ([urlOrRequest isKindOfClass:[NSString class]]) {
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlOrRequest] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
	}
	else if ([urlOrRequest isKindOfClass:[NSURLRequest class]]) {
        // let's make a copy regardless of whether or not it's mutable to avoid other people changing it beneath our feet
        request = (NSMutableURLRequest*)[urlOrRequest mutableCopyWithZone:nil];
	}
	
    // apply global HTTP header options to the request
	[HTTPHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
	
	urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	
    // turn on network activity spinner
	if (urlConnection)
		[[NetworkActivityStatus sharedManager] activityStarted:YES];
	
	return urlConnection;
}

-(void)cleanup
{
	// short circuit any possibly imminent delegate calls
	delegate = nil;
	
	if (urlConnection)
	{
		// if this is still set, we are killing off incomplete sessions
		// stop any standing asynch callback
		[urlConnection cancel];
		// make sure the fact of being killed off is accounted for in UI
		[[NetworkActivityStatus sharedManager] activityStarted:NO];
	}
	// self immolation
	[controlSet removeObject:self];
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
	[receivedData setLength:0]; 
	statusCode = [response statusCode];
	if (statusCode == 303 || statusCode == 302)
	{
//		NSLog(@"response: %@", [response allHeaderFields]);
		
		[delegate redirectReceived:identifier withURL:[[response allHeaderFields] objectForKey:@"Location"]];
		
		[self cleanup];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// turn off activity indication
	[[NetworkActivityStatus sharedManager] activityStarted:NO];
	
	// tell the delegate about the error
	// an error occured for the request (identifier) made
	//////////////////////////////////////////////////////////////
	// need to convert NSError space into human space
	// error 
	[delegate errorReceived:identifier withError:error];
	//////////////////////////////////////////////////////////////
	
	[self cleanup];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// turn off activity indication
	[[NetworkActivityStatus sharedManager] activityStarted:NO];
	
	// we have a complete data file for cacheing
	if (receivedData.length)
	{
		if ([cache isEqualToString:kCacheIDNoFileCache])
		{
			// let our delegate know that data has been received and pass it back directly
			[delegate dataReceivedWith:identifier andData:receivedData andStatus:statusCode];
		}
		else
		{
            [CacheController writeData:receivedData toCache:cache entry:name];

			// let our delegate know that data has been received
			[delegate dataReceived:identifier withStatus:statusCode];
		}
	}
	[self cleanup];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
//	if (redirectResponse)
//	{
////		NSLog(@"REDIRECT: %@", [[redirectResponse URL] absoluteString]);
////		NSLog(@"REQUEST: %@", [request allHTTPHeaderFields]);
//		return nil;
//	}
////	NSLog(@"REQUEST URL: %@", [[request URL] absoluteString]);
////	NSLog(@"REQUEST: %@", [request allHTTPHeaderFields]);
	return request;
}

@end


