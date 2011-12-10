//
//  DataHelper.m
//
//  Created by Chris Heimark on 10/13/09.
//  Copyright 2009 CHS Systems. All rights reserved.
//

#import "DataHelper.h"

#pragma mark Private implementation definition

@interface FileFetch : NSObject 
{
	NSMutableData				*receivedData;
	NSString					*name;
	
	NSUInteger					store;
	
	id<DataHelperDelegate>		delegate;
	NSURLConnection				*urlConnection;
	id							controlSet;
	NSInteger					identifier;
	NSInteger					statusCode;
}

@property (nonatomic, assign) NSUInteger	store;
@property (nonatomic, retain) NSString		*name;
@property (nonatomic, assign) NSInteger		identifier;

- (id)initWithDelegate:(id<DataHelperDelegate>)delegate andControlSet:(id)control;

- (id)retrieve:(id)urlOrRequest store:(NSUInteger)cacheStore name:(NSString*)cacheName identifier:(NSInteger)ID;

-(void)cleanup;

@end

#pragma mark -
#pragma mark Public implementation of the Data Helper class

@implementation DataHelper

NSDictionary *sHeaderItemsForAllHTTPRequests = nil;

#pragma mark -
#pragma mark Cache control class methods

+ (void)initialize
{
	// user application MUST implement this class callback
	sHeaderItemsForAllHTTPRequests = [DataHelper headerItemsForAllHTTPRequests];
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

- (NSData*)retrieve:(id)urlOrRequest store:(NSUInteger)cacheStore name:(NSString*)cacheName returnData:(BOOL)returnData identifier:(NSInteger)ID
{
	// ignore any redundant requests for the same items
	if ([self isRequestOutstandingForStore:cacheStore name:cacheName identifier:ID])
		return nil;
	
	if (cacheStore == kCacheStoreIndexNoFileCache)
		// no cache case -- always GET
		;
	else if ([CacheControl cacheSeconds:cacheStore] || !urlOrRequest)
	{
		// if this isn't a transient file, look at the cache store first
		NSString *cacheFileName = [CacheControl cachePathForStore:cacheStore name:cacheName];
		
		// see if the file is already in the cache
		if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFileName])
		{
			if (returnData)
				// yup - go fetch the data
				return [NSData dataWithContentsOfFile:cacheFileName];
			else
				return nil;
		}
		else if (!urlOrRequest)
			return nil;
	}
	
	// create a file fetch object
	FileFetch *fetchItem = [[[FileFetch alloc] initWithDelegate:delegate andControlSet:connections] autorelease];
	
	if (fetchItem)
	{
		// remember this outstanding request
		[connections addObject:fetchItem];
		
		// and make the request
		[fetchItem retrieve:urlOrRequest store:cacheStore name:cacheName identifier:ID];
	}
	return nil;
}

// methods to manually cleanup stuff
-(void)flushAllIO
{
	NSSet *snapshot = (NSSet*)[connections allObjects];
	// manually flush all standing IO
	for (FileFetch *outstanding in snapshot)
		[outstanding cleanup];
}

-(void)flushIdentifierIO:(NSInteger)ID
{
	NSSet *snapshot = (NSSet*)[connections allObjects];
	// manually flush specific IO
	for (FileFetch *outstanding in snapshot)
		if (outstanding.identifier == ID)
		{
			// this assumes only one marked with that ID
			[outstanding cleanup];
			break;
		}
}

-(BOOL)isIdentifierPendingIO:(NSInteger)ID
{
	NSSet *snapshot = (NSSet*)[connections allObjects];
	// manually flush specific IO
	for (FileFetch *outstanding in snapshot)
		if (outstanding.identifier == ID)
			return YES;

	return NO;
}

- (BOOL)isRequestOutstandingForStore:(NSUInteger)cacheStore name:(NSString*)cacheName identifier:(NSInteger)ID
{
	NSSet *snapshot = (NSSet*)[connections allObjects];
	for (FileFetch *outstanding in snapshot)
		if (outstanding.store == cacheStore && outstanding.identifier == ID && [outstanding.name isEqualToString:cacheName])
			return YES;
	
	return NO;
}


- (void)dealloc
{
	// remove any pending/incomplete requests
	[self flushAllIO];
	// and the entire control set
	[connections release];
	// and everything else
    [super dealloc];
}

@end

#pragma mark -
#pragma mark Private implementation of the File Fetch object

@implementation FileFetch

@synthesize identifier;
@synthesize store;
@synthesize name;

- (id)initWithDelegate:(id<DataHelperDelegate>)receiptDelegate  andControlSet:(id)control
{
    if ((self = [super init]))
	{
        // data comes in here
		receivedData = [[[NSMutableData alloc] initWithCapacity:4096] retain];
		delegate = receiptDelegate;
		controlSet = control;
    }
    return self;
}

- (void)dealloc
{
	// and cleanup
	[receivedData release];
	self.name = nil;
	// and finally kill self off the roster
	[super dealloc];
}

- (id)retrieve:(id)urlOrRequest store:(NSUInteger)cacheStore name:(NSString*)cacheName identifier:(NSInteger)ID
{
	self.store = cacheStore;
	self.identifier = ID;
	self.name = cacheName;
	
	NSMutableURLRequest *request;
	if ([urlOrRequest isKindOfClass:[NSString class]])
	{
		// make up a request
		request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlOrRequest] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
//		NSLog(urlOrRequest);
	}
	else if ([urlOrRequest isMemberOfClass:[NSMutableURLRequest class]])
	{
		// your basic fundamental request
		request = (NSMutableURLRequest*)urlOrRequest;
	}
	else if ([urlOrRequest isMemberOfClass:[NSURLRequest class]])
	{
		// your basic fundamental request
		request = (NSMutableURLRequest*)[[urlOrRequest mutableCopyWithZone:nil] autorelease];
	}
	else
		// ignore ignorance
		return nil;
	
	[sHeaderItemsForAllHTTPRequests enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { [request setValue:obj forHTTPHeaderField:key]; }];
	
	urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
	
	if (urlConnection)
	{
		// turn ON activity indication
		[[NetworkActivityStatus sharedManager] activityStarted:YES];
	}
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

#pragma mark -
#pragma mark Private NSURLConnection delegate protocol callbacks

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
		if (store == kCacheStoreIndexNoFileCache)
		{
			// let our delegate know that data has been received and pass it back directly
			[delegate dataReceivedWith:identifier andData:receivedData andStatus:statusCode];
		}
		else
		{
			NSString *cacheFileName = [CacheControl cachePathForStore:store name:name];
		
			[receivedData writeToFile:cacheFileName atomically:YES];

			// let our delegate know that data has been received
			[delegate dataReceived:identifier withStatus:statusCode];
		}
	}
	[self cleanup];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	if (redirectResponse)
	{
//		NSLog(@"REDIRECT: %@", [[redirectResponse URL] absoluteString]);
//		NSLog(@"REQUEST: %@", [request allHTTPHeaderFields]);
		return nil;
	}
//	NSLog(@"REQUEST URL: %@", [[request URL] absoluteString]);
//	NSLog(@"REQUEST: %@", [request allHTTPHeaderFields]);
	return request;
}

@end


