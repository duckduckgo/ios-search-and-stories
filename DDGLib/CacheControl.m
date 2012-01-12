//
//  CacheControl.m
//
//  Created by Chris Heimark on 12/12/08.
//  Copyright 2008 © DuckDuckGo, Inc. All rights reserved.
//

//hurl://www.DuckDuckGo, Inc.com/qWebServices/HomePage.aspx
//Request Headers
// Accept:application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5
// Cache-Control:max-age=0
// User-Agent:Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9

//Response Headers 
// Cache-Control:private
// Content-Length:3937
// Content-Type:text/html; charset=utf-8
// Date:Wed, 23 Sep 2009 12:18:14 GMT
// P3p:CP="IDC DSP COR LAW CURa ADMi DEVi TAIi PSAi PSDi OUR IND UNI"
// Server:Microsoft-IIS/6.0
// X-Aspnet-Version:2.0.50727
// X-Powered-By:ASP.NET
 
 
#import "CacheControl.h"
#import "NetworkActivityStatus.h" 

@implementation CacheControl

NSString *sCacheBasePath = nil;
NSArray *sCacheStorePaths = nil;
NSArray *sCacheStoreLifetimeDays = nil;

#pragma mark -
#pragma mark Cache control class methods

+ (void)initialize
{
	sCacheBasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
	
	sCacheStorePaths = [CacheControl userInitializePaths];
	sCacheStoreLifetimeDays = [CacheControl userInitializeDays];
}

+ (void)setupCaches
{
	// create the cache directories if they don't already exist
	for (NSUInteger c = 0; c < [sCacheStorePaths count]; ++c)
	{
		NSString *cachePath = [sCacheBasePath stringByAppendingPathComponent:[sCacheStorePaths objectAtIndex:c]];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
			[[NSFileManager defaultManager] createDirectoryAtPath:cachePath 
									  withIntermediateDirectories:YES 
													   attributes:nil 
															error:nil];
	}
}

+ (void)purgeCache:(NSInteger)cacheID flushAll:(BOOL)flushAll
{
	// go through and purge the caches
	NSFileManager *filemanager = [NSFileManager defaultManager];
	
	NSDate			*fileModDate;
	NSString		*file;
	NSDictionary	*fileAttributes;
	
	NSString *cachePath = [sCacheBasePath stringByAppendingPathComponent:[sCacheStorePaths objectAtIndex:cacheID]];
	
	NSDirectoryEnumerator	*dirEnum = [filemanager enumeratorAtPath:cachePath];
	NSDate					*oldestDate = [NSDate dateWithTimeIntervalSinceNow:-[[sCacheStoreLifetimeDays objectAtIndex:cacheID] intValue]];
	
	// look for candidates to delete
	while (file = [dirEnum nextObject])
	{
		fileAttributes = [filemanager attributesOfItemAtPath:[cachePath stringByAppendingPathComponent:file] error:nil];
		
		if ([NSFileTypeDirectory isEqualToString:[fileAttributes fileType]])
			continue;
		
		NSError *error = nil;
		
		if (flushAll)
			// flush all files in this cache
			[filemanager removeItemAtPath:[cachePath stringByAppendingPathComponent:file] error:&error];
		else
		{
			// selectively clear only stale files
			fileModDate	= [fileAttributes objectForKey:NSFileModificationDate];
			//			NSLog (@"filedate:%@ oldestdate: %@", fileModDate, oldestDate);
			// was file modified earlier than 
			if ([fileModDate compare:oldestDate] == NSOrderedAscending)
			{
				//				NSLog (@"Delete Path: %@, Dated: %@", file, fileModDate);
				[filemanager removeItemAtPath:[cachePath stringByAppendingPathComponent:file] error:&error];
			}
		}
//		NSLog([error localizedDescription]);
	}
}

+ (void)purgeCaches
{
	// purge all the caches except the first one which is always emptied completely
	for (NSUInteger c = 0; c < [sCacheStorePaths count]; ++c)
	{
		if (![[sCacheStoreLifetimeDays objectAtIndex:c] intValue])
			// flush ALL files in update cache
			[CacheControl purgeCache:c flushAll:YES];
		else
			// flush just stale files
			[CacheControl purgeCache:c flushAll:NO];
	}
}

+ (NSString *)cacheName:(NSInteger)cacheID
{
	return [sCacheStorePaths objectAtIndex:cacheID];
}

+ (NSInteger)cacheSeconds:(NSInteger)cacheID
{
	return [[sCacheStoreLifetimeDays objectAtIndex:cacheID] intValue];
}

+ (NSString *)cacheRootPathForStore:(NSUInteger)cacheStore
{
	return [[NSString stringWithString:sCacheBasePath] stringByAppendingPathComponent:[sCacheStorePaths objectAtIndex:cacheStore]];
}

+ (NSString *)cachePathForStore:(NSUInteger)cacheStore name:(NSString*)cacheEntry
{
	return [[CacheControl cacheRootPathForStore:cacheStore] stringByAppendingPathComponent:cacheEntry];
}

@end
